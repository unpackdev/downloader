// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";

contract drawingmachinex4 is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(address baseFactory, string memory customBaseURI_)
    ERC721Delegated(
      baseFactory,
      "drawing machine x4",
      "DRAWINGMACHINE",
      ConfigSettings({
        royaltyBps: 1000,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {}

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 100;

  uint256 public constant PRICE = 220000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 id) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");

    require(msg.value >= PRICE, "Insufficient payment, 0.22 ETH per item");

    require(id < MAX_SUPPLY, "Invalid token id");

    _mint(msg.sender, id);

    supplyCounter.increment();
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

  /** PAYOUT **/

  address private constant payoutAddress1 =
    0x2DeF8d6397c424bCe77198168ecb297Ec1BF7A5D;

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance * 60 / 100);

    Address.sendValue(payable(payoutAddress1), balance * 40 / 100);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so