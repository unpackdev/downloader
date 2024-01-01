// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote{
    

 struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
     }

    struct Proposal {
        string proposal;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    uint proposalNum = 0;
    mapping(address => mapping(uint => Voter)) public voters;
    mapping(uint => Proposal[]) public proposals;

    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals[proposalNum].length; p++) {
            if (proposals[proposalNum][p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[proposalNum][p].voteCount;
                winningProposal_ = p;
            }
        }
    }

   
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = proposals[proposalNum][winningProposal()].proposal;
    }

}