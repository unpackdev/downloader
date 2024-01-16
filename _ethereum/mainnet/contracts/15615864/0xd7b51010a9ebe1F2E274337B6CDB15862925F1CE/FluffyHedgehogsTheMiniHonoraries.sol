// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract FluffyHedgehogsTheMiniHonoraries is ERC721AQueryable, Ownable {

  using Strings for uint256;

  string public uriPrefix = "";
  string public uriSuffix = ".json";

  constructor() ERC721A("FluffyHedgehogsTheMiniHonoraries", "FHTMH") {
  }

// Function mint honorary by owner
  function mint(uint256 _mintAmount) public onlyOwner {
   _safeMint(_msgSender(), _mintAmount);
  }

// Let's start with number one
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

// Metadata things
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  // Function for setting a new URI prefix
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  // Function for setting a new URI suffix
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  // returning the URI
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
