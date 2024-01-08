// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ArtBoxTypes {
  /// @dev Main data structure for the token
  struct Box {
    uint256 id;
    bool locked;
    uint256 x;
    uint256 y;
    uint32[16][16] box;
    address minter;
    address locker;
  }
}
