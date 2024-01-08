// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./Initializable.sol";

import "./NamelessToken.sol";

contract NamelessDutchAuction is AccessControl, Initializable  {
  struct ListingWindow {
    uint64         decayStartTime;
    uint64         decayEndTime;
  }

  struct ListingPricing {
    uint           initialPrice;
    uint           finalPrice;
  }

  struct ListingStorage {
    uint32  windowId;
    uint32  pricingId;
    uint32  contractId;
    uint32  minterId;
  }

  struct ListingInput {
    ListingStorage info;
    uint[] tokenIds;
  }

  struct ListingInfo {
    uint64         decayStartTime;
    uint64         decayEndTime;
    uint           initialPrice;
    uint           finalPrice;
    NamelessToken  tokenContract;
    address        minter;
    uint[]         tokenIds;
  }

  ListingStorage[] private listings;
  mapping(uint32 => ListingWindow) private listingWindows;
  mapping(uint32 => ListingPricing) private listingPricings;
  mapping(uint32 => NamelessToken) private listingContracts;
  mapping(uint32 => address) private listingMinters;
  mapping(uint => uint[]) private listingTokenIds;

  mapping(uint => bool) public listingActive;
  mapping(uint => uint) public nextTokenIndex;

  address payable public benefactor;
  string public name;

  event ListingPurchased(uint256 indexed listingId, address indexed tokenContract, uint index, address buyer, uint256 price);

  function initialize(string memory _name, address initialAdmin) public initializer {
    name = _name;
    benefactor = payable(initialAdmin);
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
  }

  constructor(string memory _name) {
    initialize(_name, msg.sender);
  }

  function calculateCurrentPrice(ListingStorage storage template) internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = block.timestamp;
    ListingWindow storage window = listingWindows[template.windowId];
    ListingPricing storage pricing = listingPricings[template.pricingId];
    uint256 delta = pricing.initialPrice - pricing.finalPrice;

    if (currentTime >= window.decayEndTime) {
      return pricing.finalPrice;
    } else if (currentTime <= window.decayStartTime) {
      return pricing.initialPrice;
    }


    uint256 reduction =
      SafeMath.div(SafeMath.mul(delta, currentTime - window.decayStartTime ), window.decayEndTime - window.decayStartTime);
    return pricing.initialPrice - reduction;
  }

  function calculateCurrentPrice(uint256 listingId) external view returns (uint256) {
    return calculateCurrentPrice(listings[listingId]);
  }

  function bid(uint256 listingId) external payable {
    require(listingActive[listingId] != false, 'listing not active');
    require(listingId < listings.length, 'No such listing');
    ListingStorage storage listing = listings[listingId];

    require(nextTokenIndex[listingId] < listingTokenIds[listingId].length, 'Sold Out');

    uint256 currentPrice = calculateCurrentPrice(listing);
    uint256 tokenId = listingTokenIds[listingId][nextTokenIndex[listingId]];
    nextTokenIndex[listingId] = nextTokenIndex[listingId] + 1;

    address minter = listingMinters[listing.minterId];
    NamelessToken tokenContract = listingContracts[listing.contractId];

    require(msg.value >= currentPrice, 'Wrong price');
    if (minter == address(0)) {
      tokenContract.mint(msg.sender, tokenId);
    } else {
      tokenContract.mint(minter, msg.sender, tokenId);
    }

    if (currentPrice < msg.value) {
      Address.sendValue(payable(msg.sender), msg.value - currentPrice);
    }

    emit ListingPurchased(listingId, address(tokenContract), tokenId, msg.sender, currentPrice);
  }

  function addTokenContract( uint32 id, NamelessToken tokenContract ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(listingContracts[id] == NamelessToken(address(0)), 'slot taken');
    listingContracts[id] = tokenContract;
  }

  function addMinter( uint32 id, address minter ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(listingMinters[id] == address(0), 'slot taken');
    listingMinters[id] = minter;
  }

  function addWindow( uint32 id, ListingWindow calldata window ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(listingWindows[id].decayEndTime == 0, 'slot taken');
    listingWindows[id] = window;
  }

  function addPricing( uint32 id, ListingPricing calldata pricing ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(listingPricings[id].initialPrice == 0, 'slot taken');
    listingPricings[id] = pricing;
  }

  function addListings( ListingInput[] calldata newListings) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint idx = 0;
    while(idx < newListings.length) {
      uint listingId = listings.length;
      listings.push(newListings[idx].info);
      listingTokenIds[listingId] = newListings[idx].tokenIds;
      idx++;
    }
  }

  function setListingActive( uint[] calldata listingIds, bool active ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint idx = 0;
    while(idx < listingIds.length) {
      listingActive[listingIds[idx]] = active;
      idx++;
    }
  }

  function getListingsSize() external view returns (uint) {
    return listings.length;
  }

  function getListings(uint start, uint end) external view returns (ListingInfo[] memory result) {
    require(start < listings.length, 'out of range');
    require(start < end, 'out of range');
    uint size = end - start;
    uint rem = listings.length - start;
    if (size > rem) {
      size = rem;
    } else {
      end = start + rem;
    }

    result = new ListingInfo[](size);
    for (uint i = start; i < end; i++ ) {
      ListingStorage storage listing = listings[i];
      ListingWindow storage window = listingWindows[listing.windowId];
      ListingPricing storage pricing = listingPricings[listing.pricingId];
      NamelessToken tokenContract = listingContracts[listing.contractId];
      address minter = listingMinters[listing.minterId];
      result[i] = ListingInfo(
        window.decayStartTime,
        window.decayEndTime,
        pricing.initialPrice,
        pricing.finalPrice,
        tokenContract,
        minter,
        listingTokenIds[i]
      );
    }
  }

  function withdraw() external {
    require(msg.sender == benefactor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not authorized');
    uint amount = address(this).balance;
    require(amount > 0, 'no balance');

    Address.sendValue(benefactor, amount);
  }

  function setBenefactor(address payable newBenefactor, bool sendBalance) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(benefactor != newBenefactor, 'already set');
    uint amount = address(this).balance;
    address payable oldBenefactor = benefactor;
    benefactor = newBenefactor;

    if (sendBalance && amount > 0) {
      Address.sendValue(oldBenefactor, amount);
    }
  }
}
