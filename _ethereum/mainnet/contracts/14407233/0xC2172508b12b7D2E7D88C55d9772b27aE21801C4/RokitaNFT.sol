// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";

contract RokitaNFT is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(address baseFactory, string memory customBaseURI_)
    ERC721Delegated(
      baseFactory,
      "Rokita NFT",
      "ROKITA",
      ConfigSettings({
        royaltyBps: 1000,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {
    allowedMintCountMap[0xF8E10048D89F0Db9FbbDd72878ab4718CD3eC7A9] = 10000;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  function allowedMintCount(address minter) public view returns (uint256) {
    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_MULTIMINT = 10;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public nonReentrant onlyOwner {
    if (!saleIsActive) {
      if (allowedMintCount(msg.sender) >= count) {
        updateMintCount(msg.sender, count);
      } else {
        revert("Sale not active");
      }
    }

    require(count <= MAX_MULTIMINT, "Mint at most 10 at a time");

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customContractURI =
    "https://nft.ares.cx/api/contract/%7BtokenId%7D";

  function setContractURI(string memory customContractURI_) external onlyOwner {
    customContractURI = customContractURI_;
  }

  function contractURI() public view returns (string memory) {
    return customContractURI;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so