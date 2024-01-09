// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract MonocDIL is ERC721URIStorage, Ownable {
  constructor() ERC721("Drowning in Love by Monoc", "MONOCDIL") {}
  
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenURI(_tokenId, _uri);
  }
 
  function setTokenUri(uint256 _tokenId, string calldata _uri) external onlyOwner {
      super._setTokenURI(_tokenId, _uri);
  }
}