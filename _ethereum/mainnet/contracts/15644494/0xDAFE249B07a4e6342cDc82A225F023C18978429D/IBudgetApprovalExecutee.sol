// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

interface IBudgetApprovalExecutee {
    function executeByBudgetApproval(address, bytes memory, uint256) external returns (bytes memory);
    function createBudgetApprovals(address[] calldata, bytes[] calldata) external;
    function team() external view returns (address);
}