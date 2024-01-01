// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

// by @matyounatan


import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./WildNFTA.sol";

pragma solidity ^0.8.17;

contract WildxyzStandalonePromoMinter is
  Ownable,
  ReentrancyGuard
{
  WildNFTA public nft;

  error InvalidInputArrays();

  constructor() {}

  // only owner
  
  function setNFT(WildNFTA _nft) external onlyOwner {
    nft = _nft;
  }

  // promo minting methods

  function promoMint(address _to, uint256 _quantity) external onlyOwner nonReentrant {
    nft.mint(_to, _quantity);
  }

  function promoMintBatch(address[] calldata _to, uint256[] calldata _quantity)
    external
    onlyOwner nonReentrant
  {
    if (_to.length != _quantity.length) revert InvalidInputArrays();
    
    for (uint256 i = 0; i < _to.length; i++) {
      nft.mint(_to[i], _quantity[i]);
    }
  }

  function promoMintBatchSingleQuantity(address[] calldata _to, uint256 _quantity)
    external
    onlyOwner nonReentrant
  { 
    for (uint256 i = 0; i < _to.length; i++) {
      nft.mint(_to[i], _quantity);
    }
  }
}