// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IYieldDistro {
   function checkpoint() external;
   function getYield() external;
   function earned(address _account) external view returns(uint256);
}