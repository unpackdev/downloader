// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ITraits.sol";

contract Traits is ITraits, Ownable {

  // a mapping from an address to whether or not it can interact
  mapping(address => bool) private controllers;

  // mapping of generated tokens
  mapping(uint256 => bool) private tokensGenerated;
  // mapping of known token traits
  mapping(uint256 => TokenTraits) private tokenTraits;
  // mapping of alpha index rarities
  uint8[] private alphaIndexRarities;
  // mapping of alpha index aliases
  uint8[] private alphaIndexAliases;

  /**
   * create the contract and initialize the alpha index roll tables
   */
  constructor() {
    alphaIndexRarities = [8, 160, 73, 255];
    alphaIndexAliases = [2, 3, 3, 3];
  }

  /**
   * get the traits for a given token
   * @param tokenId the token ID
   * @return a struct of traits for the given token ID
   */
  function getTokenTraits(uint256 tokenId) external view override returns (TokenTraits memory) {
    require(controllers[_msgSender()], "TRAITS: Only controllers can get traits");
    require(tokensGenerated[tokenId], "TRAITS: Token doesn't exist or hasn't been revealed");

    return tokenTraits[tokenId];
  }

  /**
   * generate the traits for a token and store it in this contract
   * @param tokenId the token ID
   * @param seed the generated seed from DOS
   */
  function generateTokenTraits(uint256 tokenId, uint256 seed) external override {
    require(controllers[_msgSender()], "TRAITS: Only controllers can generate traits");

    bool isVillager = (seed & 0xFFFF) % 10 != 0;
    uint8 alphaRoll = uint8(((seed >> 16) & 0xFFFF)) % uint8(alphaIndexRarities.length);
    uint8 alphaIndex;

    if (seed >> 24 < alphaIndexRarities[alphaRoll]) {
      alphaIndex = alphaRoll;
    } else {
      alphaIndex = alphaIndexAliases[alphaRoll];
    }

    tokensGenerated[tokenId] = true;

    tokenTraits[tokenId] = TokenTraits({
      isVillager: isVillager,
      alphaIndex: alphaIndex
    });
  }

  /**
   * enables an address to interact
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from interacting
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

}
