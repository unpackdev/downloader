// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEns {
  function ensSetReverseName(address reverseRegistrar, string memory name) external;
}
