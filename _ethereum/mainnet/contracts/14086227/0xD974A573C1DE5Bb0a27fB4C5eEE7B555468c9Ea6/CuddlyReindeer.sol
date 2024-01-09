// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract CuddlyReindeer is Ownable, ERC721A, ReentrancyGuard {

  string public baseTokenURI;
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  
  struct SaleConfig {
    uint32 adoptStartTime;
    uint64 adoptPrice;
  }

  SaleConfig public saleConfig;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_
  ) ERC721A("Cuddly Reindeer", "CR", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForDevs = amountForDevs_;
  }

  //Prevent mint from another contract
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function adopt(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    
    uint256 adoptPrice = uint256(config.adoptPrice);
    uint256 adoptStartTime = uint256(config.adoptStartTime);
    
    require(
      isAdoptOn(adoptStartTime),
      "Adopt has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not adopt this many"
    );
    _safeMint(msg.sender, quantity);
    if (adoptPrice > 0){
      refundIfOver(adoptPrice * quantity);
    }
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isAdoptOn(
    uint256 adoptStartTime
  ) public view returns (bool) {
    return
      block.timestamp >= adoptStartTime;
  }

  function setupAdoptInfo(
    uint64 adoptPriceWei,
    uint32 adoptStartTime
  ) external onlyOwner {
    saleConfig = SaleConfig(
      adoptStartTime,
      adoptPriceWei
    );
  }

  // For giveaways etc.
  function devAdopt(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseTokenURI = baseURI;
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

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}