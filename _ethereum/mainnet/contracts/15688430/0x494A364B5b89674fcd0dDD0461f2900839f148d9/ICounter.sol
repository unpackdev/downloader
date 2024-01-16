// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICounter {
  function current() external view returns (uint256);
  function myResolver(string calldata pass) external view returns (bool, bytes memory);
}
