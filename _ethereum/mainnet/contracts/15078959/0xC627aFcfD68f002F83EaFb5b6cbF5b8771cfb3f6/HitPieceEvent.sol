// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Initializable.sol";
import "./IHPEvent.sol";

// import "./console.sol";

contract HitPieceEvent is Initializable, IHPEvent {

  event Minted(
    address to,
    address indexed nft,
    uint256 indexed tokenId,
    string trackId
  );

  function initialize() initializer public {}

  function emitMintEvent(
    address to,
    address nft,
    uint256 tokenId,
    string memory trackId
  ) external override {
    emit Minted(to, nft, tokenId, trackId);
  }
}
