// SPDX-License-Identifier: GPL-3.0
// Author: Pagzi Tech Inc. | 2021
pragma solidity ^0.8.11;
import "./ERC721.sol";
import "./Ownable.sol";

contract LibraryOfLyricism is ERC721, Ownable {
  string public baseURI;
  uint256 public cost = 0.08 ether;
  uint256 public maxLyrics = 60;
  uint256 public totalSupply;
  address pagzi = 0xF4617b57ad853f4Bc2Ce3f06C0D74958c240633c;
  address lyricist = 0x9f4C07a862dfc60323e5b8DC656511502Ad6E0d1;

  constructor(
    string memory _initBaseURI
  ) ERC721("Library of Lyricism", "LYRIC"){
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable{
    require(totalSupply + _mintAmount + 1 <= maxLyrics, "3" );
    require(msg.value >= cost * _mintAmount);
    for (uint256 i; i < _mintAmount; i++) {
      _safeMint(msg.sender, totalSupply + 1 + i);
    }
    totalSupply += _mintAmount;
  }

  //only owner
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(pagzi).transfer((balance * 200) / 1000);
    payable(lyricist).transfer((balance * 800) / 1000);
  }  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  function setMaxLyrics(uint256 _newMaxLyrics) public onlyOwner {
    maxLyrics = _newMaxLyrics;
  }
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
}