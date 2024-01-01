// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBooster {
   function owner() external returns(address);
   function rewardManager() external returns(address);
   function isShutdown() external returns(bool);
   function recoverERC20FromProxy(address _tokenAddress, uint256 _tokenAmount, address _withdrawTo) external;
}