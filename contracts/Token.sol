// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

abstract contract TokenInterface {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    string public name;
    string public symbol;
    uint256 public decimals;

    /// Total amount of tokens
    uint256 public totalSupply;

    /// Total tokens allotted
    uint256 public totalAlloted;

    uint256 public totalEther;

    /// _owner The address from which the balance will be retrieved
    /// return The balance
    function balanceOf(address _owner) public virtual returns (uint256 balance);

    /// Send `_amount` tokens to `_to` from `msg.sender`
    /// _to The address of the recipient
    /// _amount The amount of tokens to be transferred
    /// Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount)
        public
        virtual
        returns (bool success);

    /// Send `_amount` tokens to `_to` from `_from` on the condition it
    /// is approved by `_from`
    /// @param _from The address of the origin of the transfer
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual returns (bool success);

    /// `msg.sender` approves `_spender` to spend `_amount` tokens onpayable
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
}

contract Token is TokenInterface {
    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount)
        public
        override
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
    ) public override returns (bool success) {
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
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function giveToken(
        uint256 money,
        address _buyer,
        uint256 owner_balance
    ) public returns (bool success) {
        uint256 valueOfToken = owner_balance / totalSupply;
        uint256 numberOfToken = money / valueOfToken;
        if (numberOfToken + totalAlloted <= totalSupply) {
            balances[_buyer] += numberOfToken;
            totalAlloted += valueOfToken;
            return true;
        } else {
            return false;
        }
    }

    function revokeAllTokens(address _seller, uint256 owner_balance)
        public
        returns (uint256 balance, bool success)
    {
        if (balances[_seller] > 0) {
            uint256 valueOfToken = owner_balance / totalSupply;
            balance = balances[_seller] * valueOfToken;
            totalAlloted -= balances[_seller];
            balances[_seller] = 0;
            return (balance, true);
        } else {
            return (0, false);
        }
    }

    function getTokenRate(uint256 owner_balance)
        public
        view
        returns (uint256 rate)
    {
        return owner_balance / totalSupply;
    }
}
