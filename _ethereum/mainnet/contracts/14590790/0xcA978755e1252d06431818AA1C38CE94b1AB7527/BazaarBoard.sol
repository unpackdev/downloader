//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract BazaarBoard is Pausable, Ownable {
  using SafeERC20 for IERC20;

  struct Listing {
    uint256 price;
    uint256 timestamp;
    address lister;
    uint256 expiresAt;
  }

  struct Offer {
    address purchaser;
    uint256 price;
    OfferState status;
    uint256 expiresAt;  
    uint256 timestamp;
    bytes32 identHash;
  }

  enum OfferState{ WAITING, CANCELLED, ACCEPTED }

  mapping(address => mapping(uint256 => Listing)) public collectionToTokensToListing;
  mapping(address => mapping(uint256 => Offer[])) public collectionToTokenIdToOffers;

  mapping(address => address) public collectionToCurrency;
  mapping(address => address) public collectionToTreasury;

  address public bazaarBank;

  //2% == 200, 0.5% = 50
  mapping(address => uint256) public collectionToTreasuryFee; 
  mapping(address => uint256) public collectionToBazaarFee;

  event ListingCreated(address indexed collection, uint256 tokenid, address indexed lister, uint256 price, uint256 expiresAt, uint256 timestamp);
  event ListingRemoved(address indexed collection, uint256 tokenid, address indexed user, uint256 price, uint256 timestamp);
  event ListingBought(address indexed collection, uint256 tokenid, address indexed lister, address indexed buyer, uint256 price, uint256 timestamp);
  event ListingUpdated(address indexed collection, uint256 tokenid, address indexed lister, uint256 price, uint256 expiresAt, uint256 timestamp);

  event OfferPlaced(address indexed collection, uint256 tokenid, bytes32 identHash, address indexed purchaser, uint256 price, uint256 expiresAt, uint256 timestamp);
  event OfferCancelled(address indexed collection, uint256 tokenid, bytes32 identHash, address indexed purchaser, uint256 price, uint256 expiresAt, uint256 timestamp);
  event OfferAccepted(address indexed collection, uint256 tokenid, bytes32 identHash, address indexed purchaser, address indexed seller, uint256 price, uint256 expiresAt, uint256 timestamp);

  constructor(address _bazaar) {
    bazaarBank = _bazaar;
  }

  /* UTIL FUNCS */

  function calculateFee(uint256 price, uint256 fee) public pure returns(uint256) {
    return (price * fee) / 10000;
  }

  function handleTransfer(address collection, uint256 tokenId, uint256 price, address from, address to) internal {
    uint256 treasuryFee = calculateFee(price, collectionToTreasuryFee[collection]);
    uint256 bazaarFee = calculateFee(price, collectionToBazaarFee[collection]);

    uint256 saleProceeds = price;

    if (treasuryFee != 0) {
      saleProceeds = saleProceeds - treasuryFee;
      require(collectionToTreasury[collection] != address(0), "Invalid treasury");
      IERC20(collectionToCurrency[collection]).safeTransferFrom(to, collectionToTreasury[collection], treasuryFee);
    }

    if (bazaarFee != 0) {
      saleProceeds = saleProceeds - bazaarFee;
      IERC20(collectionToCurrency[collection]).safeTransferFrom(to, bazaarBank, bazaarFee);
    }

    
    IERC20(collectionToCurrency[collection]).safeTransferFrom(to, from, saleProceeds);
    
    IERC721(collection).safeTransferFrom(
      from,
      to,
      tokenId
    );
    
  }


  /* LISTINGS */

  modifier isValidListing(address collection, uint256 tokenId) {
    require(isListed(collection, tokenId), "Must be valid listing");
    _;
  }

  modifier isValidPrice(uint256 price) {
    require(price >= 1,"Invalid Price");
    _;
  }

  function listForSale(address collection, uint256 tokenId, uint256 price, uint256 expiresAt) external whenNotPaused isValidPrice(price) {
    if (isListed(collection, tokenId)) {
      require(getListing(collection, tokenId).expiresAt <= block.timestamp);
    }
    require(IERC721(collection).getApproved(tokenId) == address(this),"Not yet approved");
    
    collectionToTokensToListing[collection][tokenId] = Listing(
      price,
      block.timestamp,
      msg.sender,
      expiresAt
    );
    emit ListingCreated(collection, tokenId,msg.sender, price, expiresAt, block.timestamp);
  }

  function isListed(address collection, uint256 tokenId) public view returns (bool) {
    return collectionToTokensToListing[collection][tokenId].timestamp != 0;
  }

  function getListing(address collection, uint256 tokenId) public view isValidListing(collection, tokenId) returns (Listing memory) {
    Listing memory listing = collectionToTokensToListing[collection][tokenId];

    return listing;
  }

  function removeListing(address collection, uint256 tokenId) internal {
    delete collectionToTokensToListing[collection][tokenId];
  }

  function withdrawFromSale(address collection, uint256 tokenId)  isValidListing(collection, tokenId) external {
    Listing memory thisListing = collectionToTokensToListing[collection][tokenId];

    require(
      msg.sender == thisListing.lister ||
          msg.sender == owner() || IERC721(collection).ownerOf(tokenId) == msg.sender, "Must be lister/deployer/current owner"
    );
    emit ListingRemoved(collection, tokenId, msg.sender, thisListing.price, block.timestamp);

    removeListing(collection, tokenId);
  }

  function updatePrice(address collection, uint256 tokenId, uint256 price) external isValidPrice(price) {
    Listing memory thisListing = collectionToTokensToListing[collection][tokenId];

    require(
      msg.sender == thisListing.lister ||
          msg.sender == owner(), "Must be lister/deployer"
    );

    collectionToTokensToListing[collection][tokenId].price = price;
    emit ListingUpdated(collection, tokenId, msg.sender, price, thisListing.expiresAt, block.timestamp);
  }

  function updateExpiry(address collection, uint256 tokenId, uint256 expiresAt) external {
    Listing memory thisListing = collectionToTokensToListing[collection][tokenId];

    require(
      msg.sender == thisListing.lister ||
          msg.sender == owner(), "Must be lister/deployer"
    );

    require(expiresAt >= block.timestamp,"Time in past");

    collectionToTokensToListing[collection][tokenId].expiresAt = expiresAt;
    emit ListingUpdated(collection, tokenId, msg.sender, thisListing.price, expiresAt, block.timestamp);
  }

  function buyListing(address collection, uint256 tokenId, uint256 currentPrice) external whenNotPaused {
    Listing memory thisListing = getListing(collection, tokenId);
    require(thisListing.lister == IERC721(collection).ownerOf(tokenId), "Listing by previous owner");
    require(msg.sender != thisListing.lister,"You cannot buy your own listing");
    require(thisListing.price == currentPrice,"Price has changed");
    require(thisListing.expiresAt >= block.timestamp,"Listing expired");

    removeListing(collection, tokenId);

    handleTransfer(collection, tokenId, currentPrice, thisListing.lister, msg.sender);
    emit ListingBought(collection, tokenId, thisListing.lister, msg.sender, thisListing.price, block.timestamp);

  }

  /* OFFERS */

  function placeOffer(address collection, uint256 tokenId, uint256 price, uint256 expiry) external whenNotPaused isValidPrice(price) returns (bytes32) {
    require(IERC20(collectionToCurrency[collection]).balanceOf(msg.sender) >= price,"Token balance too low.");

    bytes32 ident = keccak256(abi.encodePacked(msg.sender,collection, tokenId, price, block.timestamp));
    Offer memory thisOffer = Offer(msg.sender, price, OfferState.WAITING, expiry, block.timestamp, ident);
    collectionToTokenIdToOffers[collection][tokenId].push(thisOffer);
    emit OfferPlaced(collection, tokenId,ident, msg.sender, price, expiry, block.timestamp);
    return ident;
  }

  function acceptOfferViaIdentHash(address collection, uint256 tokenId, bytes32 _identHash) external {
    Offer memory theOffer;
    uint thisIndex;
    for (uint256 i = 0; i < collectionToTokenIdToOffers[collection][tokenId].length; i++) {
      Offer memory thisOffer = collectionToTokenIdToOffers[collection][tokenId][i];
      if (thisOffer.identHash == _identHash) {
        theOffer = thisOffer;
        thisIndex = i;
      }
    }
    finalizeOfferAccepting(collection, tokenId, theOffer, thisIndex);
  }

  function acceptOfferViaIndex(address collection, uint256 tokenId, uint256 thisIndex) external {
    Offer memory theOffer = collectionToTokenIdToOffers[collection][tokenId][thisIndex];
    finalizeOfferAccepting(collection, tokenId, theOffer, thisIndex);
  }

  function cancelOfferViaIdentHash(address collection, uint256 tokenId, bytes32 _identHash) external {
    Offer memory theOffer;
    uint thisIndex;
    for (uint256 i = 0; i < collectionToTokenIdToOffers[collection][tokenId].length; i++) {
      Offer memory thisOffer = collectionToTokenIdToOffers[collection][tokenId][i];
      if (thisOffer.identHash == _identHash) {
        theOffer = thisOffer;
        thisIndex = i;
      }
    }
    finalizeOfferCancelling(collection, tokenId, theOffer, thisIndex);
  }

  function cancelOfferViaIndex(address collection, uint256 tokenId, uint256 thisIndex) external {
    finalizeOfferCancelling(collection, tokenId, collectionToTokenIdToOffers[collection][tokenId][thisIndex], thisIndex);
  }

  function finalizeOfferAccepting(address collection, uint256 tokenId, Offer memory theOffer, uint256 thisIndex) internal {
    require(block.timestamp < theOffer.expiresAt,"Offer expired");
    require(theOffer.status == OfferState.WAITING,"Offer is not available");
    collectionToTokenIdToOffers[collection][tokenId][thisIndex].status = OfferState.ACCEPTED;
    handleTransfer(collection, tokenId, theOffer.price, msg.sender, theOffer.purchaser);
    emit OfferAccepted(collection, tokenId, theOffer.identHash, theOffer.purchaser, msg.sender, theOffer.price, theOffer.expiresAt, block.timestamp);
  }

  function finalizeOfferCancelling(address collection, uint256 tokenId, Offer memory theOffer, uint256 thisIndex) internal {
    require(
      msg.sender == theOffer.purchaser ||
          msg.sender == owner(), "Must be bidder/deployer"
    );
    require(block.timestamp < theOffer.expiresAt,"Offer expired");
    collectionToTokenIdToOffers[collection][tokenId][thisIndex].status = OfferState.CANCELLED;
    emit OfferCancelled(collection, tokenId,theOffer.identHash, msg.sender, theOffer.price, theOffer.expiresAt, block.timestamp);
  }

  /* ADMIN ONLY */


  function emergencyPause() external onlyOwner {
    _pause();
  }

  function unPause() external onlyOwner {
    _unpause();
  }

  function setNewBazaarBank(address _bazaar) external onlyOwner  {
    bazaarBank = _bazaar;
  }

  function setCurrencyForCollection(address collection, address erc20) external onlyOwner {
    collectionToCurrency[collection] = erc20;
  }

  function setTreasuryForCollection(address collection, address newAddress) external onlyOwner {
    collectionToTreasury[collection] = newAddress;
  }

  function setTreasuryFeeForCollection(address collection, uint256 feeAmt) external onlyOwner {
    collectionToTreasuryFee[collection] = feeAmt;
  }

  function setBazaarFeeForCollection(address collection, uint256 feeAmt) external onlyOwner {
    collectionToBazaarFee[collection] = feeAmt;
  }

}
