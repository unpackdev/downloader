// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IStrategy {
    function deposit() external payable returns (uint256);
    function withdraw(uint256 lpAmount) external returns (uint256);
    function withdrawAll() external returns (uint256);
    function harvest(bool _compoundRewards) external;
    function getVirtualBalance() external returns (uint256);
    function getConvexLpBalance() external view returns (uint256);
}