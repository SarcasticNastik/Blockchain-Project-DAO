// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract DAO {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    string public name;
    string public symbol;
    uint256 public decimals;

    /// Total amount of tokens
    /// 1 token -> 100 wei
    uint256 public constant totalSupply = 1e18;

    /// Total tokens allotted
    uint256 public totalAlloted;

    uint256 public totalWei;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            // emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        if (
            balances[_from] >= _amount &&
            allowed[_from][msg.sender] >= _amount &&
            _amount > 0
        ) {
            balances[_to] += _amount;
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            // emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function giveToken(uint256 money, address _buyer)
        public
        returns (bool success)
    {
        uint256 numberOfToken = money / 100;
        totalWei += money;
        if (numberOfToken + totalAlloted <= totalSupply) {
            balances[_buyer] += numberOfToken;
            totalAlloted += numberOfToken;
            return true;
        } else {
            return false;
        }
    }

    function revokeAllTokens(address _seller)
        public
        returns (uint256 balance, bool success)
    {
        if (balances[_seller] > 0) {
            balance = balances[_seller] * 100;
            totalAlloted -= balances[_seller];
            totalWei -= balance;
            balances[_seller] = 0;
            return (balance, true);
        } else {
            return (0, false);
        }
    }

    function getTokenRate() public pure returns (uint256) {
        return 100;
    }

    /***********************************************************************************************/
    enum DAO_STATUS {
        NOT_INITIATED, // during this phase, request for a basic amount of ETH in exchange for tokens
        NOT_PROPOSED, // means INITIATED
        VOTING_PENDING_BID,
        VOTING_PENDING_VERIFICATION, // if invalid voting, wait till it is verified. Else,
        VOTING_BIDS_VERIFIED,
        VOTING_DECIDED // and so is transfer
    }

    struct ProposedOption {
        uint256 sno;
        string name;
        address payable addr;
    }

    // Proposal
    struct Proposal {
        address payable creator; // In case quorum is met, we transfer back the payable fee
        uint256 transfer_amount;
        uint256 num_options;
        // ProposedOption[] options; // infer the proposal status from global status
        mapping(uint256 => ProposedOption) options;
        uint256 entranceFee; // amount in ETH paid by Proposer to propose this proposal
        // FIXME: later on
    }

    struct ProposalSolution {
        bool minQuorum; // if it reaches minQuorum or not
        mapping(address => bytes32) userSecretVotes;
        // stores the userVotes after revelation is done
        // if not, rever back all of it
        // Return in order of its preference
        mapping(address => uint256[]) userVotes;
        bool decided; // store the userVotes after secret-bids whgra is done
        uint256 winner;
    }

    // if minCreationETH not reached, revert ETH to everyone back else send tokens
    uint256 constant maxCreationPeriod = 5 seconds;
    uint256 constant votingSecretPeriod = 10 seconds;
    uint256 constant votingNormalPeriod = 10 seconds;
    // revert to new proposal on failing this
    uint256 constant maxProposalPeriod = 10 seconds;
    uint256 constant loopbackTimeout = 10 seconds;
    uint256 constant minPayableFee = 1e4;
    uint256 constant minQuorumRatio = 4; // 1:4 i.e. atleast 25% of the voters must decide on the value

    // minimum ETH required for creation of the DAO
    uint256 constant minCreationETH = 1e6;

    DAO_STATUS daoStatus;
    address[] usersWithTokens;
    address[] usersWithoutToken;
    uint256 globalSeed;
    address payable immutable owner;
    // mapping(Proposal => uint256) proposalFee;
    // Proposal[] public proposals;
    Proposal public proposal;
    // ProposalSolution[] finalDecisions;
    ProposalSolution currProposalSolution;
    uint256 initTime;
    uint256 initialFunds;

    address[] usersWhoVoted;
    uint256[] votesAcquired;

    event TimeDiff(uint256 startTime, uint256 endTime);

    event OwnerFunds(address payable _addr, uint256 balance);

    constructor() {
        owner = payable(msg.sender);
        globalSeed = 42;
        daoStatus = DAO_STATUS.NOT_INITIATED;
        initTime = block.timestamp;
        emit TimeDiff(initTime, initTime);
        // initialFunds = owner.balance;
        totalWei = 0;
    }

    function payThis(address payable addr, uint256 price) public payable {
        if (price > 0) {
            require(msg.value >= price);
            addr.transfer(price);
        }
    }

    // user utilities
    // maxCreationPeriod min modifier and status modifier (require)
    function userReqToken(uint256 _amt) public payable returns (bool success) {
        require(
            block.timestamp - initTime <= maxCreationPeriod,
            "user can only request tokens in creation period"
        );
        require(
            daoStatus == DAO_STATUS.NOT_INITIATED,
            "user can only request tokens in creation period"
        );
        // sent _amt in ETH
        payThis(owner, (_amt / 100) * 100);

        usersWithTokens.push(address(msg.sender));
        giveToken(_amt, address(msg.sender));
        return true;
    }

    function userRevokeToken() public payable returns (bool) {
        require(
            block.timestamp - initTime <= maxCreationPeriod,
            "users can only revoke tokens in creation period"
        );
        require(
            daoStatus == DAO_STATUS.NOT_INITIATED,
            "users can only revoke tokens in creation period"
        );

        usersWithoutToken.push(address(msg.sender));
        emit TimeDiff(block.timestamp, initTime);
        return true;
    }

    function currTokenRate() public view returns (uint256) {
        require(
            block.timestamp - initTime <= maxCreationPeriod,
            "user can only request current rate in creation period"
        );
        require(daoStatus == DAO_STATUS.NOT_INITIATED);

        return getTokenRate();
    }

    modifier ownerOnly() {
        require(
            address(msg.sender) == address(owner),
            "only owner is allowed to execute this function"
        );
        _;
    }
    event SuccessInitDao(bool);

    // initDAO
    // - check changes in token object (mappings of users to tokens)
    // - test for
    //   1. Status of dao
    //   2. Time taken
    function initDAO() public ownerOnly {
        require(daoStatus == DAO_STATUS.NOT_INITIATED, "can't initialize DAO");
        require(
            block.timestamp - initTime > maxCreationPeriod,
            "still waiting for users to buy tokens"
        );
        emit TimeDiff(block.timestamp, initTime);

        if (totalWei >= minCreationETH) {
            // success
            emit SuccessInitDao(true);
            daoStatus = DAO_STATUS.NOT_PROPOSED;
            for (uint256 i = 0; i < usersWithoutToken.length; i++) {
                (uint256 amt, ) = revokeAllTokens(usersWithoutToken[i]); // if not success, then balances never really existed.
                payThis(payable(usersWithoutToken[i]), amt);
            }
            initTime = block.timestamp;
            daoStatus = DAO_STATUS.NOT_PROPOSED;
        } else {
            emit SuccessInitDao(false);
            for (uint256 i = 0; i < usersWithTokens.length; i++) {
                (uint256 amt, ) = revokeAllTokens(usersWithTokens[i]);
                // if not success, then balances never really existed.
                payThis(payable(usersWithTokens[i]), amt);
            }
            initTime = block.timestamp;
        }
    }

    modifier usersWithTokensOnly() {
        require(
            balanceOf(msg.sender) > 0,
            "only users with tokens allowed to use this function"
        );
        _;
    }

    function propose(string memory nname, address payable addr)
        public
        payable
        usersWithTokensOnly
    {
        require(
            (daoStatus == DAO_STATUS.NOT_PROPOSED &&
                ((block.timestamp - initTime) <= maxProposalPeriod)) ||
                (daoStatus == DAO_STATUS.VOTING_DECIDED &&
                    ((block.timestamp - initTime) > loopbackTimeout))
        );
        require(
            proposal.creator == address(0x0) ||
                proposal.creator == payable(msg.sender),
            "different proposers can't propose concurrently"
        );
        proposal.creator = payable(msg.sender);
        proposal.options[proposal.num_options].name = nname;
        proposal.options[proposal.num_options].sno = proposal.num_options;
        proposal.options[proposal.num_options].addr = addr;
        proposal.num_options += 1;
        initTime = block.timestamp;
        daoStatus = DAO_STATUS.VOTING_PENDING_BID;
    }

    /**
      @notice Create digest for a secret-bid placed by some manufacturer.
      @return ABI-encoded Keccak256 hash of provided parameters
     */
    function generateBidHash(uint256[] memory arr)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(msg.sender, arr));
    }

    // Voting
    function secretBid(bytes32 secretRanking) public usersWithTokensOnly {
        require(
            daoStatus == DAO_STATUS.VOTING_PENDING_BID,
            "secret bids aren't pending yet"
        );
        require(
            block.timestamp - initTime <= votingSecretPeriod,
            "secret bid period is either over or didn't happen yet"
        );

        currProposalSolution.userSecretVotes[
            address(msg.sender)
        ] = secretRanking;
    }

    function verifyQuorum() public ownerOnly {
        require(
            daoStatus == DAO_STATUS.VOTING_PENDING_BID,
            "quorum can't be checked without pending bids"
        );
        require(
            block.timestamp - initTime > votingSecretPeriod,
            "can't check quorum within secret bid period"
        );

        uint256 totalVotersBidding = 0;
        for (uint256 i = 0; i < usersWithTokens.length; i++) {
            bool take = true;
            for (uint256 j = 0; j < usersWithoutToken.length; j++) {
                if (usersWithTokens[i] == usersWithoutToken[j]) take = false;
            }
            if (take) {
                if (
                    currProposalSolution.userSecretVotes[usersWithTokens[i]] !=
                    0x0
                ) {
                    totalVotersBidding += 1;
                }
            }
        }

        if (
            totalVotersBidding >=
            (usersWithTokens.length - usersWithoutToken.length) / minQuorumRatio
        ) {
            daoStatus = DAO_STATUS.VOTING_PENDING_VERIFICATION;
            initTime = block.timestamp;
            currProposalSolution.minQuorum = true;
        } else {
            // fallback to no proposal
            currProposalSolution.minQuorum = false;
            currProposalSolution.decided = false;

            for (uint256 i = 0; i < usersWithTokens.length; i++) {
                (uint256 amt, ) = revokeAllTokens(usersWithTokens[i]);
                // if not success, then balances never really existed.
                payThis(payable(usersWithTokens[i]), amt);
            }

            proposal.creator = payable(address(0x0));
            proposal.entranceFee = 0;
            ProposedOption memory tmp;
            for (uint256 i = 0; i < proposal.num_options; i++)
                proposal.options[i] = tmp;
            proposal.num_options = 0;
            proposal.transfer_amount = 0;
            initTime = block.timestamp;

            daoStatus = DAO_STATUS.NOT_PROPOSED;
        }
    }

    function revealBid(uint256[] memory ranking) public usersWithTokensOnly {
        require(
            daoStatus == DAO_STATUS.VOTING_PENDING_VERIFICATION,
            "revealed bids shouldn't be called yet"
        );
        require(
            block.timestamp - initTime <= votingNormalPeriod,
            "can only reveal bids in revelation period"
        );

        bytes32 hsh = generateBidHash(ranking);
        if (hsh == currProposalSolution.userSecretVotes[address(msg.sender)]) {
            currProposalSolution.userVotes[address(msg.sender)] = ranking;
        }
    }

    function verifyAllBids() public ownerOnly {
        require(
            daoStatus == DAO_STATUS.VOTING_PENDING_VERIFICATION,
            "revealed bids shouldn't be called yet"
        );
        require(
            block.timestamp - initTime > votingNormalPeriod,
            "can verify all bids only after revealing all of them"
        );

        bool ok = true;
        for (uint256 i = 0; i < usersWithTokens.length; i++) {
            bool take = true;
            for (uint256 j = 0; j < usersWithoutToken.length; j++) {
                if (usersWithTokens[i] == usersWithoutToken[j]) take = false;
            }
            if (currProposalSolution.userSecretVotes[usersWithTokens[i]] == 0x0)
                take = false;

            if (take) {
                if (
                    currProposalSolution.userVotes[usersWithTokens[i]].length ==
                    0
                ) ok = false;
            }
        }

        if (ok) {
            daoStatus = DAO_STATUS.VOTING_BIDS_VERIFIED;
            initTime = block.timestamp;
        } else {
            //  fallback mechanism
            currProposalSolution.minQuorum = false;
            currProposalSolution.decided = false;

            for (uint256 i = 0; i < usersWithTokens.length; i++) {
                (uint256 amt, ) = revokeAllTokens(usersWithTokens[i]);
                // if not success, then balances never really existed.
                payThis(payable(usersWithTokens[i]), amt);
            }

            proposal.creator = payable(address(0x0));
            proposal.entranceFee = 0;
            ProposedOption memory tmp;
            for (uint256 i = 0; i < proposal.num_options; i++)
                proposal.options[i] = tmp;
            proposal.num_options = 0;
            proposal.transfer_amount = 0;

            initTime = block.timestamp;
            daoStatus = DAO_STATUS.NOT_PROPOSED;
        }
    }

    // DAO acc -> winner payment
    // 1. Find winner through majority voting
    // 2. Pay the requisite amount
    function takeDecision() public payable ownerOnly {
        require(
            daoStatus == DAO_STATUS.VOTING_BIDS_VERIFIED,
            "decision taking isn't required"
        );

        // Take the decision of checking all the reveals here

        for (uint256 i = 0; i < usersWithTokens.length; i++) {
            bool take = true;
            for (uint256 j = 0; j < usersWithoutToken.length; j++) {
                if (usersWithTokens[i] == usersWithoutToken[j]) take = false;
            }
            if (currProposalSolution.userVotes[usersWithTokens[i]].length == 0)
                take = false;

            if (take) {
                usersWhoVoted.push(usersWithTokens[i]);
            }
        }

        for (uint256 i = 0; i < proposal.num_options; i++) {
            votesAcquired.push(0);
        }
        for (uint256 i = 0; i < usersWhoVoted.length; i++) {
            votesAcquired[
                currProposalSolution.userVotes[usersWhoVoted[i]][0]
            ] += balanceOf(usersWhoVoted[i]);
        }

        uint256 winner = 0;
        uint256 weightedVotes = 0;
        for (uint256 i = 0; i < votesAcquired.length; i++) {
            if (votesAcquired[i] > weightedVotes) {
                weightedVotes = votesAcquired[i];
                winner = i;
            }
        }
        currProposalSolution.decided = true;
        currProposalSolution.winner = winner;

        Proposal storage win_option = proposal;
        payThis(win_option.options[winner].addr, win_option.transfer_amount);
        initTime = block.timestamp;

        // currProposal Reset
        currProposalSolution.decided = false;
        currProposalSolution.minQuorum = false;
        // for (uint256 i = 0; i < usersWhoVoted.length; b i++) {
        //     currProposalSolution.userSecretVotes[usersWhoVoted[i]] = 0x0;
        //     currProposalSolution.userVotes[usersWhoVoted[i]] = arr;
        // }
        currProposalSolution.winner = 0;

        daoStatus = DAO_STATUS.VOTING_DECIDED;
    }

    function currWinner() public view returns (string memory) {
        require(
            daoStatus == DAO_STATUS.VOTING_DECIDED,
            "voting for proposal isn't over yet"
        );
        require(currProposalSolution.decided, "Proposal failed!");
        return proposal.options[currProposalSolution.winner].name;
    }
}
