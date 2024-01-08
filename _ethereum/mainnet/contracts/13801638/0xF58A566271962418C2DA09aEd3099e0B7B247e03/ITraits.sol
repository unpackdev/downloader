// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
  struct TokenTraits {
    bool isVillager;
    uint8 alphaIndex;
  }

  function getTokenTraits(uint256 tokenId) external view returns (TokenTraits memory);
  function generateTokenTraits(uint256 tokenId, uint256 seed) external;
}
