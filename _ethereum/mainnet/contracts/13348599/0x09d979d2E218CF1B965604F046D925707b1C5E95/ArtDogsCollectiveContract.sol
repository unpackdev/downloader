// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract ArtDogsCollectiveContract is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  address constant founder = 0x75cb4B8b76760ac74C51919a643cC317FD034303;
  address constant payout = 0xCDe3d8af04558Db620625A42799ecb025131A0cb;

  uint256 constant _price = 0.02 ether;
  uint256 private constant _mintLimit = 50;
  uint256 private constant _supplyLimit = 20000;
  bool private baseURISet = false;
  bool public paused = true;
  string _baseTokenURI;
  string _unrevealedURI;

  string constant imageProvenance = "f1751775bc38f835e1942da8868a7046509ade8e23281087fb4e5d74b59ef132";

  mapping(address => uint256) private _minted;

  constructor(string memory unrevealedURI) ERC721("Art Dogs Collective", "ADC") {
    _unrevealedURI = unrevealedURI;

    _safeMint(founder, 0);
    _safeMint(payout, 1);
  }

  function remainingMint(address user) public view returns (uint256) {
    return _mintLimit - _minted[user];
  }

  function mint(uint256 num) public payable nonReentrant {
    uint256 supply = totalSupply();
    require(!paused || msg.sender == owner(), "Sale paused");
    require(remainingMint(msg.sender) >= num, "You can mint a maximum of 50 dogs");
    require(supply + num < _supplyLimit, "Exceeds maximum supply");
    require(msg.value >= _price * num, "Ether sent is not correct");

    _minted[msg.sender] += num;

    for (uint256 i; i < num; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    require(!baseURISet, "Base URI must not already be set");

    _baseTokenURI = baseURI;
    baseURISet = true;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return
      bytes(_baseTokenURI).length > 0 && baseURISet
        ? string(abi.encodePacked(_baseTokenURI, tokenId.toString()))
        : _unrevealedURI;
  }

  function getPrice() public pure returns (uint256) {
    return _price;
  }

  function setPaused(bool val) public onlyOwner {
    paused = val;
  }

  function withdrawAll() public onlyOwner {
    payable(payout).transfer(address(this).balance);
  }
}

// We like the cats AND dogs
