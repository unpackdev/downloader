// SPDX-License-Identifier: GPL-3.0-or-later

// The Boys of Summer - by Mitchell F Chan
// Presented by Wildxyz

pragma solidity ^0.8.17;

import "./Strings.sol";
import "./Base64.sol";
import "./Math.sol";

import "./WildNFT.sol";

contract PROXYBIDDERSEDITION is WildNFT {

  constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator) WildNFT("PROXY BIDDERS EDITION", 'PROXYBE', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {}

  // batch minting

  function mintBatch(address[] memory _to, uint256[] memory _quantities) public onlyMinter {
    for (uint256 i = 0; i < _to.length; i++) {
      address to = _to[i];
      for (uint256 j = 0; j < _quantities[i]; j++) {
        mint(to);
      }
    }
  }

  // update 2981 royalty
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), 'Token does not exist.');
    return string(abi.encodePacked(baseURI));
  }
}