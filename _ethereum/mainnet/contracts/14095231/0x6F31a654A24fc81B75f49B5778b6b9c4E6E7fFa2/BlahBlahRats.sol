// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract BlahBlahRats is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;

  address private refundAddress = 0xcBAc616ccFC9802246D105A68880Cc001c8EfF69;

  struct SaleConfig {
    uint32 publicSaleStartTime;
    uint64 publicPrice;
    uint64 allowlistPrice;
  }

  SaleConfig public saleConfig;

  mapping(address => uint256) public allowlist;

  constructor(uint256 maxBatchSize_, uint256 collectionSize_, uint256 amountForDevs_)
  ERC721A("BlahBlahRats", "BBRAT", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForDevs = amountForDevs_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function allowlistMint(uint256 quantity) external payable callerIsUser {
    uint256 price = uint256(saleConfig.allowlistPrice);

    require(price != 0, "allowlist sale has not begun yet");
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    require(allowlist[msg.sender] >= quantity, "cannot mint that much");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");

    allowlist[msg.sender] = allowlist[msg.sender] - quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(price * quantity);
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);

    require(isPublicSaleOn(publicPrice, publicSaleStartTime), "public sale has not begun yet");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "cannot mint this many");

    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  uint256 public constant FREE_MINT_DURATION = 66 minutes;
  uint256 public constant FREE_MINT_NUMBER = 666;
  uint256 public constant FREE_MINT_PER_WALLET = 1;
  uint256 public freeMintOffset;
  bool public freeMintOffsetUpdated = false;

  function updateFreeMintOffset() external onlyOwner {
    require(!freeMintOffsetUpdated, "offset already updated");

    freeMintOffset = totalSupply();
    freeMintOffsetUpdated = true;
  }

  function freeMint() external payable callerIsUser {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
    require(isFreeMintOn(publicPrice, publicSaleStartTime), "free mint is over or has not yet started");
    require(numberMinted(msg.sender) + 1 <= FREE_MINT_PER_WALLET, "cannot free mint this many");
    _safeMint(msg.sender, 1);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "need to send more ETH");
    if (msg.value > price) {
      payable(refundAddress).transfer(msg.value - price);
    }
  }

  function isFreeMintOn(uint256 publicPriceWei, uint256 publicSaleStartTime) public view returns (bool) {
    return publicPriceWei != 0 && block.timestamp > publicSaleStartTime && block.timestamp < (publicSaleStartTime + FREE_MINT_DURATION) && totalSupply() < freeMintOffset + FREE_MINT_NUMBER;
  }

  function isPublicSaleOn(uint256 publicPriceWei, uint256 publicSaleStartTime) public view returns (bool) {
    return publicPriceWei != 0 && block.timestamp >= publicSaleStartTime;
  }

  function setPublicPrice(uint64 price) external onlyOwner {
    saleConfig.publicPrice = price;
  }

  function setAllowlistPrice(uint64 price) external onlyOwner {
    saleConfig.allowlistPrice = price;
  }

  function setPublicSaleStartTime(uint32 time) external onlyOwner {
    saleConfig.publicSaleStartTime = time;
  }

  function setSaleConfig(uint32 publicSaleStartTime, uint64 publicPrice, uint64 allowlistPrice) external onlyOwner {
    saleConfig = SaleConfig(
      publicSaleStartTime,
      publicPrice,
      allowlistPrice
    );
  }

  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
    require(addresses.length == numSlots.length, "addresses does not match numSlots length");
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }
}
