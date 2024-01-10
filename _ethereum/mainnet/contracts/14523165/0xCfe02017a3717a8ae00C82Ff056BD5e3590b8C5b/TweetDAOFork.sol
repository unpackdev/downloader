// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";

contract TweetDAOFork is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(address baseFactory, string memory customBaseURI_)
    ERC721Delegated(
      baseFactory,
      "Tweet DAO Fork",
      "TDF",
      ConfigSettings({
        royaltyBps: 1000,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {}

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 1500;

  uint256 public constant MAX_MULTIMINT = 10;

  uint256 public constant PRICE = 50000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 10 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.05 ETH per item"
    );

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

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_tokenURI(tokenId), ".token.json"));
  }

  /** PAYOUT **/

  address private constant payoutAddress1 =
    0x4af51Bb39a619cEF7D2ccf7046996c7f54Ea8c73;

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance * 90 / 100);

    Address.sendValue(payable(payoutAddress1), balance * 10 / 100);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so