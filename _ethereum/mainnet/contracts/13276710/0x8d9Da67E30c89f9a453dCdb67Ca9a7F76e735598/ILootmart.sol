// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Any component stores need to have this function so that Adventurer can determine what
// type of item it is
interface ILootmart {
  function itemTypeFor(uint256 tokenId) external view returns (string memory);
}
