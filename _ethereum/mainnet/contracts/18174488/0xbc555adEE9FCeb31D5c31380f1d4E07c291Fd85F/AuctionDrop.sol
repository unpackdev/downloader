// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./PolyOneDrop.sol";
import "./IPolyOneDrop.sol";

/**
 * @title PolyOne Auction Drop
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Implements the functionality required for English Auctions in the PolyOne contract ecosystem
 */
contract AuctionDrop is IPolyOneDrop, PolyOneDrop {
  mapping(uint256 dropId => mapping(uint256 tokenIndex => Bid currentBid)) public highestBid;

  constructor(address _polyOneCore) PolyOneDrop(_polyOneCore) {}

  function registerPurchaseIntent(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _bidder,
    uint256 _amount,
    bytes calldata
  ) external payable onlyPolyOneCore returns (bool, address, string memory, Royalties memory) {
    Drop storage drop = _validatePurchaseIntent(_dropId, _tokenIndex);
    Bid memory currentBid = highestBid[_dropId][_tokenIndex];
    uint256 minimumBid = currentBid.amount == 0 ? drop.startingPrice : currentBid.amount + drop.bidIncrement;

    if (_amount < minimumBid) {
      revert InvalidPurchasePrice(_amount);
    }

    if (currentBid.amount != 0) {
      polyOneCore.transferEth(currentBid.bidder, currentBid.amount);
    }

    highestBid[_dropId][_tokenIndex] = Bid(_bidder, _amount);

    uint64 bidExtensionTime = polyOneCore.bidExtensionTime();

    if (drop.startDate + drop.dropLength - block.timestamp < bidExtensionTime) {
      drop.dropLength += bidExtensionTime;
      emit DropExtended(_dropId, drop.dropLength);
    }

    return (false, drop.collection, "", drop.royalties);
  }

  function validateTokenClaim(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _caller,
    bytes calldata
  ) external onlyPolyOneCore returns (address, string memory, Bid memory, Royalties memory) {
    if (!listingEnded(_dropId, _tokenIndex)) {
      revert DropInProgress(_dropId);
    }
    if (claimed[_dropId][_tokenIndex]) {
      revert TokenAlreadyClaimed(_dropId, _tokenIndex);
    }
    Bid memory currentBid = highestBid[_dropId][_tokenIndex];
    if (currentBid.bidder != _caller && !_validateDelegatedClaim(_dropId, _caller)) {
      revert InvalidClaim(_dropId, _tokenIndex, _caller);
    }
    claimed[_dropId][_tokenIndex] = true;
    return (drops[_dropId].collection, drops[_dropId].baseTokenURI, currentBid, drops[_dropId].royalties);
  }

  function listingActive(uint256 _dropId, uint256) external view returns (bool) {
    return
      PolyOneLibrary.isDateInPast(drops[_dropId].startDate) &&
      !PolyOneLibrary.isDateInPast(drops[_dropId].startDate + drops[_dropId].dropLength);
  }

  function listingEnded(uint256 _dropId, uint256) public view returns (bool) {
    return PolyOneLibrary.isDateInPast(drops[_dropId].startDate + drops[_dropId].dropLength);
  }

  function listingClaimed(uint256 _dropId, uint256 _tokenIndex) external view returns (bool) {
    return claimed[_dropId][_tokenIndex];
  }
}
