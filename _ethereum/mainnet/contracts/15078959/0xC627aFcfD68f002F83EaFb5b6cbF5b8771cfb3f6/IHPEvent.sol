// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IHPEvent {
  function emitMintEvent(
    address to,
    address nft,
    uint256 tokenId,
    string memory trackId
  ) external virtual;
}