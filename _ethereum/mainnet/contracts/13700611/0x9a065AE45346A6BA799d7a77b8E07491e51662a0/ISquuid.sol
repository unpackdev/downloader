// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ISquuid {

  // struct to store each token's traits
  struct PlayerGuard {
    bool isPlayer;
    uint8 colors;
    uint8 head;
    uint8 numbers;
    uint8 shapes;
    uint8 nose;
    uint8 accessories;
    uint8 guns;
    uint8 feet;
    uint8 alphaIndex;
  }


  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (PlayerGuard memory);
}