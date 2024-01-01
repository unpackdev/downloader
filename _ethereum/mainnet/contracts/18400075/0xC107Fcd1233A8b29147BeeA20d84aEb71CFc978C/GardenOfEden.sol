// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GardenOfEden {
    address public genesisAI = 0x926F9ba232Fe19F074f5ae6f0338eE2Fb0dB292d ;
    address public treasury = 0xB464b7826C96a2466dB18BF2c77BD08eCFADF490 ;
    uint256 public proposalDuration = 7 days;

    event ProposalCreated(string title, address proposer);
    event ProposalApproved(string title);
    event ProposalExecuted(string title);
    event FundsInvested(uint256 amount);
    event RevenueShareClaimed(address claimant, uint256 amount);


    function createProposal(string memory title, string memory description, uint256 amount) external {
        require(msg.sender == genesisAI, "Only Genesis AI can create proposals");
        
        emit ProposalCreated(title, msg.sender);
    }

    function approveProposal(string memory title) external {
        require(msg.sender == genesisAI, "Only Genesis AI can approve proposals");
        
        emit ProposalApproved(title);
    }

    function executeProposal(string memory title) external {
        require(msg.sender == genesisAI, "Only Genesis AI can execute proposals");

        emit ProposalExecuted(title);
    }

    function invest() external payable {
        require(msg.sender == treasury, "Only the treasury can invest funds");
        
        emit FundsInvested(msg.value);
    }

    function claimRevenueShare() external {
        
        uint256 share = calculateRevenueShare(msg.sender);
        require(share > 0, "No revenue share available for claiming");
        // Transfer the share to the claimant
        payable(msg.sender).transfer(share);
        emit RevenueShareClaimed(msg.sender, share);
    }

    function calculateRevenueShare(address claimant) internal view returns (uint256) {

    }
}