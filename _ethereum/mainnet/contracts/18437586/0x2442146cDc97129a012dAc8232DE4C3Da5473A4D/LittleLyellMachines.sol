// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import "./Strings.sol";
import "./Base64.sol";
import "./Math.sol";

import "./IERC721A.sol";
import "./ERC721A.sol";

import "./WildNFTA.sol";

import "./MetadataP5JS.sol";

contract LittleLyellMachines is WildNFTA {

  MetadataP5JS public metadata;

  constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator) WildNFTA('Little Lyell Machines', 'LLM', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {}

  // metadata methods

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {
    if (from != address(0)) return;

    for (uint256 i = 0; i < quantity; i++) {
      metadata.generateTokenHash(startTokenId + i, to);
    }
  }

  // only OwnerMetadataP5JS

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setMetadata(MetadataP5JS _metadata) public onlyOwner {
    metadata = _metadata;
  }

  // public

  function tokenHTML(uint256 _tokenId) public view virtual tokenExists(_tokenId) returns (string memory) {
    return metadata.tokenHTML(_tokenId);
  }

  function tokenURI(uint256 _tokenId) public view override(IERC721A, ERC721A) tokenExists(_tokenId) returns (string memory) {
    return metadata.tokenURI(_tokenId);
  }
}
