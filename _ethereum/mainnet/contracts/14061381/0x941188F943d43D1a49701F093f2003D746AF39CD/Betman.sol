// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Betman is ERC721Enumerable, Ownable {
  uint256 public constant MAX_SUPPLY = 520;
  uint256 public constant MAX_MINT = 2;
  uint256 public constant WHITE_MINT_PRICE = 50000000000000000; // mint price: 0.05 eth
  uint256 public constant PUBLIC_MINT_PRICE = 80000000000000000; // mint price: 0.08 eth

  uint256 public publicStartTime = 1643180400; // 2022.01.26 3 PM (GMT+8)
  uint256 public publicEndTime = 1643266800;  // 2022.01.27 3 PM (GMT+8)
  bool public whitelistIsActive = false;
  bool public publicsaleIsActive = false;
  string private baseURI;
  
  mapping(address => uint8) private _whiteList;

  constructor(
  ) ERC721("Betman", "BM") {
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setbaseURI(string memory baseURI_) external onlyOwner() {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function flippublicsale(bool newState) public onlyOwner() {
    publicsaleIsActive = newState;
  }

  function flipwhitesale(bool newState) public onlyOwner() {
    whitelistIsActive = newState;
  }

  function numberWhiteMint(address addr) external view returns (uint8) {
     return _whiteList[addr];
  }

  function setPublicMintTime(uint256 startTime, uint256 endTime) external onlyOwner {
    publicStartTime = startTime;
    publicEndTime = endTime;
  }

  function setWhiteList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      _whiteList[addresses[i]] = 2;
    }
  }

  function mintWhiteList(uint8 numberOfTokens) external payable {
    uint totalToken = totalSupply();
    require(whitelistIsActive, "White list is not active");
    require(numberOfTokens <= _whiteList[msg.sender], "Exceed available tokens");
    require(WHITE_MINT_PRICE * numberOfTokens <= msg.value, "Ether value is insufficient");
    require(totalToken + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed token supply");

    _whiteList[msg.sender] -= numberOfTokens;
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, totalToken + i);
    }
  }
  
  function mint(uint256 numberOfTokens) public payable {
    uint256 totalToken = totalSupply();
    require(block.timestamp >= publicStartTime, "Public mint not begin yet");
    require(block.timestamp <= publicEndTime, "Public mint ended");
    require(publicsaleIsActive, "Sale must be active to mint tokens");
    require(numberOfTokens <= MAX_MINT, "Number of mint exceed MAX_MINT");
    require(totalToken + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed token supply");
    require(PUBLIC_MINT_PRICE * numberOfTokens <= msg.value, "Ether value is insufficient");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, totalToken + i);
    }
  }

  function reserve(uint256 numberReserved) public onlyOwner {
    uint totalToken = totalSupply();
    uint i;
    for (i = 0; i < numberReserved; i++) {
      _safeMint(msg.sender, totalToken + i);
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    Address.sendValue(payable(owner()), balance);
  }
}
