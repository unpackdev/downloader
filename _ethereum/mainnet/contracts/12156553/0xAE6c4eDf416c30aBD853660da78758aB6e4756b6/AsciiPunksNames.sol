// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AsciiPunks.sol";

contract AsciiPunksNames {
  mapping(uint256 => string) names;
  AsciiPunks private punks;

  constructor(address payable _punksAddress) {
    punks = AsciiPunks(_punksAddress);
  }

  modifier validNFToken(uint256 tokenId) {
    address owner = punks.ownerOf(tokenId);
    require(owner != address(0), "ERC721: query for nonexistent token");

    _;
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = punks.ownerOf(tokenId);

    return owner;
  }

  function setName(uint256 tokenId, string memory newName)
    external
    returns (string memory)
  {
    require(msg.sender == ownerOf(tokenId), 'This method is only callable by the owner of the token');

    names[tokenId] = newName;

    return names[tokenId];
  }

  function getName(uint256 tokenId)
    external
    view
    validNFToken(tokenId)
    returns (string memory)
  {
    string memory name = names[tokenId];

    return name;
  }
}
