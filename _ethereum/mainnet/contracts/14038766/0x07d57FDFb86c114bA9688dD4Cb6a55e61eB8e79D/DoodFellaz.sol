// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract DoodFellaz is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForAuctionAndDev;
  uint256 public mintPrice = 0.025 ether;

  struct SaleConfig {
    uint32 auctionSaleStartTime;
    uint32 publicSaleStartTime;
    uint64 mintlistPrice;
    uint64 publicPrice;
    uint32 publicSaleKey;
  }

  SaleConfig public saleConfig;

  bool isSaleOn = false;

  mapping(address => uint256) public allowlist;

  IERC721 Doodles = IERC721(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e);
  IERC721 DeadFellaz = IERC721(0x2acAb3DEa77832C09420663b0E1cB386031bA17B);

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    string memory baseURI
  ) ERC721A("DoodFellaz", "DOODFELLAZ", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForAuctionAndDev = collectionSize_;

    _baseTokenURI = baseURI;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function doesOwnDoodleOrDeadFellaz(address address_) internal view returns(bool) {
    bool isDoodlesOwner = Doodles.balanceOf(address_) > 0;
    bool isDeadFellazOwner = DeadFellaz.balanceOf(address_) > 0;

    return isDoodlesOwner || isDeadFellazOwner; 
  }

  function calculatePrice(uint256 quantity) internal view returns (uint256) {
    bool isEligibleForPromotion = doesOwnDoodleOrDeadFellaz(msg.sender);

    uint freeQuantity = isEligibleForPromotion ? quantity / 5 : 0;

    return (quantity - freeQuantity) * mintPrice;
  }

  function publicSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    require(
      isPublicSaleOn(),
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    
    _safeMint(msg.sender, quantity);

    uint price = calculatePrice(quantity);
    refundIfOver(price);
  }

  function setMintPrice (uint256 price) external onlyOwner {
      mintPrice = price;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isPublicSaleOn() public view returns (bool) {
    return isSaleOn;
  }

  function toggleSale() public onlyOwner {
      isSaleOn = !isSaleOn;
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