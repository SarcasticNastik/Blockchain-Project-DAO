// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

// Contract Proposal-> Contractor
// Contract Acceptance -> Random Curators (holding our DAI-MA)
                    // -> ["SECRETKEY"]
// wait time for eth->daima conversion for users
// Proposal made public 
// Voting phase for users start
      // Copy paste from previous codebase with secret-bids.
// End Voting phase
// Decision on proposal release


import "./Token.sol"

contract DAO_Interface { 

  uint constant maxCreationPeriod = 10 minutes;

  uint constact minCreationETH = 10;
  
  // revert to new proposal on failing this
  uint constant minProposalDebatePeriod = 1 seconds;

  uint constant tokenBuyPeriod = 5 minutes;

  uint constant votingPeriod = 10 minutes;
  // revert to new proposal on failing this
  uint constant executeProposalPeriod = 20 minutes; 

  Token token;
  
  enum DAO_STATUS {
    NOT_INITIATED, // during this phase, request for a basic amount of ETH in exchange for tokens
    INITIATED, // only after minimum amount of ETH is accepted from everyone
    NOT_PROPOSED,
    PROPOSAL_IN_CONSIDERATION,
    PROPOSAL_ACCEPTED,
    BUYING_TIME, // token-buying lockout time
    VOTING_NOT_STARTED,
    VOTING_PENDING_BID,
    VOTING_PENDING_VERIFICATION,
    VOTING_BIDS_VERIFIED,
    VOTING_DECIDED, // loops back to NOT_PROPOSED after some timeout
  } 

  // Proposal
  //  - Transfer minimum payable fee to avoid proposal spam
  struct Proposal {
    address recipient;
    uint amount; 
  }

  address public curator;

}

contract DAO is DAO_Interface { 
 // contains some owned amount of ETH, it gives DAI-MA in it's respect.
 //
}
