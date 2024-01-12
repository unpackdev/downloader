// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Owned.sol";
import "./Strings.sol";

contract NFTrees is ERC721, Owned {
  using Strings for uint;

  uint immutable public totalSupply;
  string public baseURI;

  constructor  (
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    address[] memory destinations
  ) ERC721(_name, _symbol) Owned(msg.sender) {

    for (uint i = 0; i < destinations.length; ++i) {
      _mint(destinations[i], i + 1);
    }

    baseURI = _baseURI;
    totalSupply = destinations.length;
  }

  function tokenURI(uint tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
  }

  function setURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

}
