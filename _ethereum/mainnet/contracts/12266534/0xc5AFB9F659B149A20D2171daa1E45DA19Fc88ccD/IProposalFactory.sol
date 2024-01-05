// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


import "./IProposal.sol";

/**
 * @dev Interface for a Bitgem staking pool
 */
interface IProposalFactory {
    /**
     * @dev emitted when a new gem pool proposal has been added to the system
     */
    event ProposalCreated(address creator, uint256 proposalType, address proposal);

    event ProposalFunded(uint256 indexed proposalHash, address indexed funder, uint256 expDate);

    event ProposalExecuted(uint256 indexed proposalHash, address pool);

    event ProposalClosed(uint256 indexed proposalHash, address pool);

    function getProposal(uint256 _symbolHash) external view returns (address);

    function allProposals(uint256 idx) external view returns (address);

    function allProposalsLength() external view returns (uint256);

    function createProposal(
        address submitter,
        string memory title,
        address proposalData,
        IProposal.ProposalType proposalType
    ) external returns (address payable);
}
