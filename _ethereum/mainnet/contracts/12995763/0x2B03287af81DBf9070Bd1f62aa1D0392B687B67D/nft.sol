// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./nf-token-metadata.sol";
import "./ownable.sol";
 
contract newNFT is NFTokenMetadata, Ownable {
 
  constructor() {
    nftName = "CuriousAxolotl";
    nftSymbol = "AXOLOTL";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
}