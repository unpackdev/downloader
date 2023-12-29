// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBooster {
   function owner() external returns(address);
   function rewardManager() external returns(address);
   function isShutdown() external returns(bool);
}