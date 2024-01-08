// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVesting {
    function getVestingPlan(address) external view returns (uint256);
    function addNewRecipient(address, uint256, uint256) external;
    function addNewRecipients(address[] memory, uint256[] memory, uint256[] memory) external;
    function startVesting(uint256) external;
    function getLocked(address) external view returns (uint256);
    function getWithdrawable(address) external view returns (uint256);
    function withdrawToken(address) external returns (uint256);
    function getVested(address) external view returns (uint256);
}
