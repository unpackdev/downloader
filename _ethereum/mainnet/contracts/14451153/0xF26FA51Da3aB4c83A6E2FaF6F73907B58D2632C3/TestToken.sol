// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";

contract TestToken is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor(string memory customBaseURI_) ERC721("TestToken", "TTKN") {
    customBaseURI = customBaseURI_;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 10;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 5000;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public constant PRICE = 90000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant onlyOwner {
    require(saleIsActive, "Sale not active");

    if (allowedMintCount(msg.sender) >= count) {
      updateMintCount(msg.sender, count);
    } else {
      revert("Minting limit exceeded");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.09 ETH per item"
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

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** PAYOUT **/

  address private constant payoutAddress1 =
    0xf49D5d989c9Bfc0c437517FDeD3444Bd7B48A395;

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(payoutAddress1), balance);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so