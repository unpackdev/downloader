// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./Ownable.sol";

contract Datapoems is ERC721, Ownable {

  string private baseTokenURI;
  mapping(uint256 => string) private metadataURIs;

  function mint(address recipient, uint256 tokenId, string memory metadataURI) external onlyOwner {
    _safeMint(recipient, tokenId);
    metadataURIs[tokenId] = metadataURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
    return string(abi.encodePacked(baseTokenURI, metadataURIs[tokenId]));
  }

  function updateBaseURI(string calldata baseURIOverride) external onlyOwner {
    baseTokenURI = baseURIOverride;
  }

  constructor() ERC721("Datapoems", "DTPM") {}
}