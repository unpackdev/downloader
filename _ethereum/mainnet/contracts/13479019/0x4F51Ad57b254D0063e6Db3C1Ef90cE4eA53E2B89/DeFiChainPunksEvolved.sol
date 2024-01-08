// SPDX-License-Identifier: GPL-3.0

// Created by @madeinusmate
// The DeFiChain Punks Evolved

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DeFiChainPunksEvolved is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  uint256 public cost = 0.015 ether;
  bool public paused = false;

  constructor(
    string memory _initBaseURI
  ) ERC721("DeFiChain Punks Evolved", "DEFIPUNKSEVOLVED") {
    setBaseURI(_initBaseURI);
    mint(msg.sender, 19);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
   function contractURI() public pure returns (string memory) {
        return "https://api-madeinusmate.herokuapp.com/defichain-punks-evolved/contract_metadata.json";
    }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(supply + _mintAmount <= 300);

    if (msg.sender != owner()) {
          require(msg.value >= cost * _mintAmount);
          require(_mintAmount <= 2);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }


  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}