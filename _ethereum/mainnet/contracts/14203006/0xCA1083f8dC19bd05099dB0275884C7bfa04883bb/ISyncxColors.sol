// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ISYNC {
  function mint(uint256 _mintAmount, uint16[] calldata colorsTokenIds)
    external
    payable;

  function updateColors(uint256 tokenId, uint16[] calldata colorsTokenIds)
    external
    payable;
}
