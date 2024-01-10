// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFlashGovernor {
    function proposalEndBlock(uint32 proposalId)
        external
        view
        returns (uint256);

    function propose() external returns (uint32);

    function execute(uint32 proposalId) external;

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Executed
    }

    function state(uint32 proposalId) external view returns (ProposalState);
}
