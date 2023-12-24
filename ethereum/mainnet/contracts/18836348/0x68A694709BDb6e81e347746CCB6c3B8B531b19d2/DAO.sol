// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OrbDAO {

    address public admin;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votes;

    struct Proposal {
        uint256 id;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
    }

    event NewProposal(uint256 proposalId, string description);
    event Vote(uint256 proposalId, bool inSupport, address voter);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier validProposal(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        _;
    }

    function init() external {
        require(admin == address(0),"Already Set");
        admin = msg.sender;
    }

    function createProposal(string memory description) external onlyAdmin {
        proposalCount++;
        proposals[proposalCount] = Proposal(proposalCount, description, 0, 0, false);
        emit NewProposal(proposalCount, description);
    }

    function vote(uint256 proposalId, bool inSupport) external validProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal has already been executed");

        if (votes[msg.sender] == 0) {
            if (inSupport) {
                proposal.forVotes++;
            } else {
                proposal.againstVotes++;
            }
            votes[msg.sender] = proposalId;
            emit Vote(proposalId, inSupport, msg.sender);
        }
    }

    function executeProposal(uint256 proposalId) external onlyAdmin validProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal has already been executed");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        require(totalVotes > 0, "No votes cast for the proposal");

        if (proposal.forVotes > proposal.againstVotes) {
            // Execute the proposal
            proposal.executed = true;
            // Add your execution logic here
        }
    }
}
