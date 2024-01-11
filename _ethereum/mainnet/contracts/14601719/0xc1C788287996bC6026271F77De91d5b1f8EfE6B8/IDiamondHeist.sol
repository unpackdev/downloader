// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";

interface IDiamondHeist is IERC721Upgradeable, IERC721MetadataUpgradeable {

  // struct to store each token's traits
  struct LlamaDog {
    bool isLlama;
    uint8 body;
    uint8 hat;
    uint8 eye;
    uint8 mouth;
    uint8 clothes;
    uint8 tail;
    uint8 alphaIndex;
  }

  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (LlamaDog memory);
  function isLlama(uint256 tokenId) external view returns(bool);
}