// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./AccessControl.sol";

import "./OwnableClone.sol";
import "./ISaleable.sol";

import "./BinaryDecoder.sol";

contract VFAuctions is AccessControl {
  struct Listing {
    uint16    template;
    uint16    consigner;
    uint16    offeringId;
  }

  struct ListingTemplate {
    uint64    openTime;
    uint16    startOffsetMin;
    uint16    endOffsetMin;
    uint16    startPriceTenFinnies;
    uint16    priceReductionTenFinnies;
  }

  address[] internal consigners;
  bytes32[0xFFFF] internal listings;
  bytes32[0xFFFF] internal templates;
  uint256 internal numListings;
  mapping (uint256 => bool) internal listingPurchased;
  address payable public benefactor;

  string public name;

  event ListingPurchased(uint256 indexed listingId, uint16 index, address buyer, uint256 price);

  constructor(string memory _name) {
    name = _name;
    benefactor = payable(msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  uint256 constant private TEN_FINNY_TO_WEI = 10000000000000000;

  function calculateCurrentPrice(ListingTemplate memory template) internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = block.timestamp;
    uint256 delta = uint256(template.priceReductionTenFinnies) * TEN_FINNY_TO_WEI;
    uint256 startPrice = uint256(template.startPriceTenFinnies) * TEN_FINNY_TO_WEI;
    uint64 startTime = template.openTime + (uint64(template.startOffsetMin) * 60);
    uint64 endTime = template.openTime + (uint64(template.endOffsetMin) * 60);

    if (currentTime >= endTime) {
      return startPrice - delta;
    } else if (currentTime <= startTime) {
      return startPrice;
    }


    uint256 reduction =
      SafeMath.div(SafeMath.mul(delta, currentTime - startTime ), endTime - startTime);
    return startPrice - reduction;
  }

  function calculateCurrentPrice(uint256 listingId) public view returns (uint256) {
    require(numListings >= listingId, 'No such listing');
    Listing memory listing = decodeListing(uint16(listingId));
    ListingTemplate memory template = decodeTemplate(listing.template);
    return calculateCurrentPrice(template);
  }

  function bid(
    uint256 listingId
  ) public payable {
    require(listingPurchased[listingId] == false, 'listing sold out');
    require(numListings >= listingId, 'No such listing');
    Listing memory listing = decodeListing(uint16(listingId));
    ListingTemplate memory template = decodeTemplate(listing.template);

    uint256 currentPrice = calculateCurrentPrice(template);
    require(msg.value >= currentPrice, 'Wrong price');
    ISaleable(consigners[listing.consigner]).processSale(listing.offeringId, msg.sender, currentPrice);
    listingPurchased[listingId] = true;

    emit ListingPurchased(listingId, listing.offeringId, msg.sender, currentPrice);

    if (currentPrice < msg.value) {
      Address.sendValue(payable(msg.sender), msg.value - currentPrice);
    }
  }

  function addConsigners( address[] memory newConsigners ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint idx = 0; idx < newConsigners.length; idx++) {
      consigners.push(newConsigners[idx]);
    }
  }

  function addListings( bytes32[] calldata newListings, uint offset, uint length) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint idx = 0;
    while(idx < newListings.length) {
      listings[offset + idx] = newListings[idx];
      idx++;
    }
    numListings = length;
  }

  function addListingTemplates( bytes32[] calldata newTemplates, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint idx = 0;
    while(idx < newTemplates.length) {
      templates[offset + idx] = newTemplates[idx];
      idx++;
    }
  }

  struct OutputListing {
    uint16   listingId;
    address  consigner;
    uint16[] soldOfferingIds;
    uint16[] availableOfferingIds;
    uint256  startPrice;
    uint256  endPrice;
    uint64   startTime;
    uint64   endTime;
    uint64   openTime;
  }

  function getListingsLength() public view returns (uint) {
    return numListings;
  }

  function getListings(uint16 start, uint16 length) public view returns (OutputListing[] memory) {
    require(start < numListings, 'out of range');
    uint256 remaining = numListings - start;
    uint256 actualLength = remaining < length ? remaining : length;
    OutputListing[] memory result = new OutputListing[](actualLength);

    for (uint16 idx = 0; idx < actualLength; idx++) {
      uint16 listingId = start + idx;
      Listing memory listing = decodeListing(listingId);
      ListingTemplate memory template = decodeTemplate(listing.template);
      bool isPurchased = listingPurchased[listingId];

      result[idx].listingId   = listingId;
      result[idx].consigner   = consigners[listing.consigner];

      if (isPurchased) {
        result[idx].soldOfferingIds = new uint16[](1);
        result[idx].availableOfferingIds = new uint16[](0);
        result[idx].soldOfferingIds[0] = listing.offeringId;
      } else {
        result[idx].soldOfferingIds = new uint16[](0);
        result[idx].availableOfferingIds = new uint16[](1);
        result[idx].availableOfferingIds[0] = listing.offeringId;
      }

      uint256 reduction = uint256(template.priceReductionTenFinnies) * TEN_FINNY_TO_WEI;
      uint256 startPrice = uint256(template.startPriceTenFinnies)  * TEN_FINNY_TO_WEI;
      uint64 startTime = template.openTime + (uint64(template.startOffsetMin) * 60);
      uint64 endTime = template.openTime + (uint64(template.endOffsetMin) * 60);

      result[idx].startPrice  = startPrice;
      result[idx].endPrice    = startPrice - reduction;
      result[idx].startTime   = startTime;
      result[idx].endTime     = endTime;
      result[idx].openTime   = template.openTime;
    }

    return result;
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function decodeListing(uint16 idx) internal view returns (Listing memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 6);
    Listing memory result;

    (result.template,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);
    (result.consigner,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);
    (result.offeringId,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(listings, bufferIndex, offset);

    return result;
  }

  function decodeTemplate(uint16 idx) internal view returns (ListingTemplate memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 16);
    ListingTemplate memory result;

    (result.openTime,bufferIndex,offset) = BinaryDecoder.decodeUint64Aligned(templates, bufferIndex, offset);
    (result.startOffsetMin,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.endOffsetMin,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.startPriceTenFinnies,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);
    (result.priceReductionTenFinnies,bufferIndex,offset) = BinaryDecoder.decodeUint16Aligned(templates, bufferIndex, offset);

    return result;
  }

  function withdraw() public {
    require(msg.sender == benefactor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not authorized');
    uint amount = address(this).balance;
    require(amount > 0, 'no balance');

    Address.sendValue(benefactor, amount);
  }

  function setBenefactor(address payable newBenefactor, bool sendBalance) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(benefactor != newBenefactor, 'already set');
    uint amount = address(this).balance;
    address payable oldBenefactor = benefactor;
    benefactor = newBenefactor;

    if (sendBalance && amount > 0) {
      Address.sendValue(oldBenefactor, amount);
    }
  }
}
