// SPDX-License-Identifier: None
pragma solidity 0.8.8;

import "./Ownable.sol";
import "./ERC721.sol";

contract HonoraryCryptoBatz is Ownable, ERC721 {
  mapping(uint256 => string) private _tokenURIs;

  uint256 public totalSupply;

  constructor() ERC721("Honorary CryptoBatz by Ozzy Osbourne", "HBATZ") { }

  function mintTo(address recipient, string calldata uri) public onlyOwner {
    totalSupply++;

    _tokenURIs[totalSupply] = uri;
    _safeMint(recipient, totalSupply);
  }

  function updateMetadata(uint256 tokenId, string calldata uri) public onlyOwner {
    require(_exists(tokenId), "Nonexistent token");

    _tokenURIs[tokenId] = uri;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "Nonexistent token");

    return _tokenURIs[tokenId];
  }
}