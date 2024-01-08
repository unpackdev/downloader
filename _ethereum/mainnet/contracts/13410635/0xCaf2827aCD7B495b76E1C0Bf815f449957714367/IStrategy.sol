// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

interface IStrategy {
    function deposit() external payable returns (uint256);
    function withdraw(uint256 lpAmount) external returns (uint256);
    function withdrawAll() external returns (uint256);
    function harvest() external;
    function setPoolId(uint256 _poolId) external;
    function getVirtualBalance() external returns (uint256);
    function getConvexLpBalance() external view returns (uint256);
    function setRewardManager(address) external;
}