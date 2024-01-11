// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC1967Proxy {
  event Upgraded(address indexed implementation);

  function implementation() external view returns (address);

  function upgrade(address newImplementation) external payable;

  function upgradeAndCall(address newImplementation, bytes calldata data) external payable;
}
