pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

import "./ISmileToken.sol";
import "./Ownable.sol";

contract SmileOfDAO is Ownable {

    address public executionWallet;
    ISmileToken public token;
    uint256 public proposalID;

    struct Proposal{
        address owner;
        bool isApproved;
        bool isCompleted;
        uint256 upVote;
        uint256 downVote;
        uint256 abstainVote;
    }
    mapping(uint256 => Proposal) public proposal;
    mapping(uint256 => mapping(address => bool)) public votedUser;

    event ProposalCreated(uint256 id, address createdBy);
    event ProposalApproved(uint256 id, address approvedBy);
    event ProposalCompleted(uint256 id, address completeBy);
    event Voting(uint256 id, address voteBy);

    constructor(address _token){
        token = ISmileToken(_token);
    }

    function setExecutionAddress(address _newExecutionAddress) external onlyOwner{
        require(_newExecutionAddress != address(0), "Not allow 0 address");
        executionWallet = _newExecutionAddress;  
    }

    function createProposal() public onlyOwner returns(uint256 id){
        proposalID++;
        proposal[proposalID] = Proposal({
            owner: msg.sender,
            isApproved: false,
            isCompleted: false,
            upVote: 0,
            downVote: 0,
            abstainVote: 0
        });
        emit ProposalCreated(proposalID, msg.sender);
        return proposalID;
    }

    function approveProposal(uint256 _proposalID) external onlyOwner {
        require(proposalID >= _proposalID, "Proposal not exist");
        require(!proposal[_proposalID].isCompleted, "Proposal is completed");
        proposal[_proposalID].isApproved = true;
    }

    function completeProposal(uint256 _proposalID) external onlyOwner {
        require(proposalID >= _proposalID, "Proposal not exist");
        require(proposal[_proposalID].isApproved, "Proposal not approved");
        require(!proposal[_proposalID].isCompleted, "Proposal is completed");
        proposal[_proposalID].isCompleted = true;
    }

    // _voteType = 1 : Up Vote
    // _voteType = 2 : Down Vote
    // _voteType = 3 : Nutral Vote
    function voteProposal(uint256 _proposalID, uint256 _voteType) public {
        require(token.balanceOf(msg.sender) >= 1, "Not enough NFT in your account");
        require(proposalID >= _proposalID, "Proposal not exist");
        require(proposal[_proposalID].isApproved, "Proposal not approved");
        require(!proposal[_proposalID].isCompleted, "Proposal is completed");
        require(!votedUser[_proposalID][msg.sender], "Already vote on this");

        if(_voteType == 1){
            proposal[_proposalID].upVote = proposal[_proposalID].upVote + token.balanceOf(msg.sender);
        } else if(_voteType == 2){
            proposal[_proposalID].downVote = proposal[_proposalID].downVote + token.balanceOf(msg.sender);
        } else if(_voteType == 3){
            proposal[_proposalID].abstainVote = proposal[_proposalID].abstainVote + token.balanceOf(msg.sender);
        }

        votedUser[_proposalID][msg.sender] = true;
    }

}