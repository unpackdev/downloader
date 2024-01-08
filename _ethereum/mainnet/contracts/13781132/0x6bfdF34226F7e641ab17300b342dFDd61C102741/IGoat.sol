// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IGoat {

  // struct to store each token's traits
  struct GoatTortoise {
    bool isTortoise;
    uint8 fur;
    uint8 skin;
    uint8 ears;
    uint8 eyes;
    uint8 shell;
    uint8 face;
    uint8 neck;
    uint8 feet;
    uint8 accessory;
    uint8 fertilityIndex;
  }

  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (GoatTortoise memory);
}