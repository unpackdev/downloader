// SPDX-License-Identifier: UNLICENSED

// 🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺
// ███╗   ███╗ █████╗ ██████╗ ███████╗    ██╗    ██╗██╗████████╗██╗  ██╗    ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝    ██║    ██║██║╚══██╔══╝██║  ██║    ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗      ██║ █╗ ██║██║   ██║   ███████║    ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝      ██║███╗██║██║   ██║   ██╔══██║    ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗    ╚███╔███╔╝██║   ██║   ██║  ██║    ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝     ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
// 🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Address.sol";
import "./Counters.sol";

contract MasonUkraineRelief is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  uint256 public PRICE;
  uint256 public MAX_SUPPLY;
  uint256 public MAX_RESERVED_SUPPLY;
  uint256 public MAX_PUBLIC_SUPPLY;
  uint256 public MAX_PER_WALLET;
  uint256 public MAX_MULTIMINT;

  Counters.Counter private supplyCounter;
  Counters.Counter private reservedSupplyCounter;

  PaymentSplitter private _splitter;

  constructor (
    string memory tokenName,
    string memory tokenSymbol,
    string memory customBaseURI_,
    address[] memory payees,
    uint256[] memory shares,
    uint256 _tokenPrice,
    uint256 _tokensForSale,
    uint256 _tokensReserved) ERC721(tokenName, tokenSymbol) {
    customBaseURI = customBaseURI_;

    PRICE = _tokenPrice;
    MAX_SUPPLY = _tokensForSale;
    MAX_RESERVED_SUPPLY = _tokensReserved;
    MAX_PUBLIC_SUPPLY = MAX_SUPPLY - MAX_RESERVED_SUPPLY;

    MAX_PER_WALLET = 100;
    MAX_MULTIMINT = 100;

    _splitter = new PaymentSplitter(payees, shares);
  }

  /** MINTING **/

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(totalPublicSupply() + count - 1 < MAX_PUBLIC_SUPPLY, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");
    require(
      msg.value >= PRICE * count, "Insufficient payment"
    );

    if (allowedMintCount(msg.sender) > count) {
      updateMintCount(msg.sender, count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      supplyCounter.increment();
      _safeMint(msg.sender, totalSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function ownerMint(uint256 count, address recipient) external onlyOwner() {
    require(totalReservedSupply() + count - 1 < MAX_RESERVED_SUPPLY, "Exceeds max reserved supply");
    require(totalSupply() + count - 1 < MAX_SUPPLY , "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      reservedSupplyCounter.increment();
      _safeMint(recipient, totalSupply());
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current() + reservedSupplyCounter.current();
  }

  function totalPublicSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  function totalReservedSupply() public view returns (uint256) {
    return reservedSupplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  /** ADMIN **/

  function setPrice(uint256 _tokenPrice) external onlyOwner {
    PRICE = _tokenPrice;
  }

  function setMultiMint(uint256 _maxMultimint) external onlyOwner {
    MAX_MULTIMINT = _maxMultimint;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    MAX_PER_WALLET = _maxPerWallet;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MAX_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function baseTokenURI() public view returns (string memory) {
    return customBaseURI;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** PAYOUT **/

  function release(address payable account) public virtual onlyOwner {
    _splitter.release(account);
  }
}
