pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


interface LinkTokenInterfaceSimplified {
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
}