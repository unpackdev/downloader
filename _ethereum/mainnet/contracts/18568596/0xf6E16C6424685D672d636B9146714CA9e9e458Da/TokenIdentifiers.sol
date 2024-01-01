// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./Strings.sol";

/*
    DESIGN NOTES:
    Token ids are a concatenation of:
   * creator: hex address of the creator of the token. 160 bits
   * index: Index for this token (the regular ID), up to 2^56 - 1. 56 bits
   * collection: Virtual collection id for this token, up to 2^40 - 1 (1 trillion).  40 bits

  */
/**
 * @title TokenIdentifiers
 * support for authentication and metadata for token ids
 */

library TokenIdentifiers {
  uint56 private constant MAX_INDEX = 0xFFFFFFFFFFFFFF;
  uint40 private constant MAX_COLLECTION = 0xFFFFFFFFFF;

  // Function to create a token ID based on creator, index, and supply
  function createTokenId(address creator, uint256 index, uint256 collection) internal pure returns (uint256) {
    // Concatenate the values into a single uint256 token ID
    uint256 tokenID = (uint256(uint160(creator)) << 96) | (uint256(index) << 40) | uint256(collection);
    return tokenID;
  }

  function tokenCreator(uint256 _id) internal pure returns (address) {
    return address(uint160(_id >> 96));
  }

  function tokenIndex(uint256 _id) internal pure returns (uint56) {
    return uint56((_id >> 40) & MAX_INDEX);
  }

  function tokenCollection(uint256 _id) internal pure returns (uint40) {
    return uint40(_id & MAX_COLLECTION);
  }

  // Function to extract creator, index, and supply from a token ID
  function decodeTokenId(uint256 _id) internal pure returns (address creator, uint56 index, uint40 collection) {
    creator = tokenCreator(_id);
    index = tokenIndex(_id);
    collection = tokenCollection(_id);
  }
}
