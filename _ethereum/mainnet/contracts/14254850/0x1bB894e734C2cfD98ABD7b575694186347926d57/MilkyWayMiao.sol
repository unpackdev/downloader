// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract MilkyWayMiao is Ownable, ERC721A, ReentrancyGuard {
  uint256 public constant MAX_SUPPLY = 888;
  uint256 public constant MAX_BATCH_SIZE = 2;
  uint256 public constant AMOUNT_FOR_DEV = 40;

  address public immutable fundHolder;

  struct WhitelistSaleConfig {
    uint8 phase;
    uint32 startTime;
    uint32 endTime;
    uint64 price;
  }

  struct AuctionSaleConfig {
    uint32 startTime;
    uint32 timeStep;
    uint64 startPrice;
    uint64 endPrice;
    uint64 priceStep;
    uint32 supply;
    uint8 maxPerWallet;
  }

  WhitelistSaleConfig public whitelistSaleConfig;
  AuctionSaleConfig public auctionSaleConfig;

  // phase => address => quantity
  mapping(uint8 => mapping(address => uint8)) public whitelist;

  constructor(address fundHolder_) ERC721A('MilkyWay Miao One', 'MiOne', MAX_BATCH_SIZE, MAX_SUPPLY) {
    require(fundHolder_ != address(0));
    fundHolder = fundHolder_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'The caller is another contract');
    _;
  }

  function auctionMint() external payable callerIsUser {
    require(
      auctionSaleConfig.startTime != 0 && block.timestamp >= auctionSaleConfig.startTime,
      'auction sale has not started yet'
    );
    require(auctionSaleConfig.supply > 0, 'auction sold out');
    require(numberMinted(msg.sender) < auctionSaleConfig.maxPerWallet, 'can not mint this many');
    auctionSaleConfig.supply--;

    mintMiao(1, getAuctionPrice());
  }

  function whitelisted(uint8 phase_, address addr_) public view returns (uint8) {
    return whitelist[phase_][addr_];
  }

  function whitelistMint(uint8 quantity) external payable callerIsUser {
    require(whitelistSaleConfig.price != 0, 'whitelist sale has not initialized yet');
    require(block.timestamp >= uint256(whitelistSaleConfig.startTime), 'whitelist sale has not started yet');
    require(block.timestamp < uint256(whitelistSaleConfig.endTime), 'whitelist sale is finished');
    require(whitelisted(whitelistSaleConfig.phase, msg.sender) >= quantity, 'not eligible for whitelist mint');
    whitelist[whitelistSaleConfig.phase][msg.sender] -= quantity;

    mintMiao(quantity, whitelistSaleConfig.price);
  }

  function mintMiao(uint8 quantity_, uint256 price_) private {
    require(totalSupply() + quantity_ <= collectionSize, 'reached max supply');
    _safeMint(msg.sender, quantity_);
    refundIfOver(price_ * quantity_);
  }

  function refundIfOver(uint256 cost) private {
    require(msg.value >= cost, 'Need to send more ETH.');
    if (msg.value > cost) {
      payable(msg.sender).transfer(msg.value - cost);
    }
  }

  function getAuctionPrice() public view returns (uint256) {
    if (block.timestamp < auctionSaleConfig.startTime) {
      return 0;
    }
    uint256 step = (block.timestamp - auctionSaleConfig.startTime) / auctionSaleConfig.timeStep;
    return
      (auctionSaleConfig.startPrice - auctionSaleConfig.endPrice) > step * auctionSaleConfig.priceStep
        ? auctionSaleConfig.startPrice - step * auctionSaleConfig.priceStep
        : auctionSaleConfig.endPrice;
  }

  function seedWhitelist(
    uint8 phase_,
    address[] memory addresses_,
    uint8[] memory numSlots_
  ) external onlyOwner {
    require(addresses_.length == numSlots_.length, 'addresses does not match numSlots length');
    for (uint256 i = 0; i < addresses_.length; i++) {
      whitelist[phase_][addresses_[i]] = numSlots_[i];
    }
  }

  function setWhitelistSale(
    uint8 phase_,
    uint32 startTime_,
    uint32 endTime_,
    uint64 price_
  ) external onlyOwner {
    whitelistSaleConfig = WhitelistSaleConfig(phase_, startTime_, endTime_, price_);
  }

  function setAuctionSale(
    uint32 startTime_,
    uint32 timeStep_,
    uint64 startPrice_,
    uint64 endPrice_,
    uint64 priceStep_,
    uint32 supply_,
    uint8 maxPerWallet_
  ) external onlyOwner {
    auctionSaleConfig = AuctionSaleConfig(
      startTime_,
      timeStep_,
      startPrice_,
      endPrice_,
      priceStep_,
      supply_,
      maxPerWallet_
    );
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= AMOUNT_FOR_DEV, 'too many already minted before dev mint');
    require(quantity % maxBatchSize == 0, 'can only mint a multiple of the maxBatchSize');
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(fundHolder, maxBatchSize);
    }
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = fundHolder.call{ value: address(this).balance }('');
    require(success, 'Transfer failed.');
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
