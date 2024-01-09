// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AOwnersExplicit.sol";
import "./Strings.sol";

contract AdaliaIDEarlyAdopter is Ownable, ERC721A, ERC721AOwnersExplicit, ReentrancyGuard {
  uint256 public immutable maxBatchSize;
  uint256 public immutable amountForDevs;
  uint256 public immutable collectionSize;

  struct SaleConfig {
    uint32 publicSaleStartTime;
    uint64 publicPrice;
  }

  SaleConfig public saleConfig;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_
  ) ERC721A("adalia.id Early Adopter", "AID.EA") {
    maxBatchSize = maxBatchSize_;
    amountForDevs = amountForDevs_;
    collectionSize = collectionSize_;
    require(
      amountForDevs_ <= collectionSize_,
      "larger collection size needed"
    );
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setSaleConfig(
    uint32 publicSaleStartTime,
    uint64 publicPriceWei
  ) external onlyOwner {
    saleConfig = SaleConfig(
      publicSaleStartTime,
      publicPriceWei
    );
  }

  function publicSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
    
    require(
      isPublicSaleOn(publicPrice, publicSaleStartTime),
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxBatchSize,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isPublicSaleOn(
    uint256 publicPriceWei,
    uint256 publicSaleStartTime
  ) public view returns (bool) {
    return
      publicPriceWei != 0 &&
      block.timestamp >= publicSaleStartTime;
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= amountForDevs, "too many already minted before dev mint");
    require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize");
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

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
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