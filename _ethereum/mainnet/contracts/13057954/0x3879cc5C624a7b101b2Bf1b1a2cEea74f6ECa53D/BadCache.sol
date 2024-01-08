//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract BadCache is ERC721URIStorage, Ownable {
  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  function setTokenUri(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(_tokenId, _tokenURI);
  }

  function mint(address _owner, uint256 _tokenId) public onlyOwner {
    _safeMint(_owner, _tokenId);
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }
}
