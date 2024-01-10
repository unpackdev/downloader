// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITRAC {
  struct TokenTime { uint16 token; uint48 timestamp; }
  struct OwnerTime { address owner; uint48 timestamp; }
  function tokenTimesOf(address) external view returns (TokenTime[] memory);
  function ownerTimesOf(uint16[] calldata) external view returns (OwnerTime[] memory);
}
