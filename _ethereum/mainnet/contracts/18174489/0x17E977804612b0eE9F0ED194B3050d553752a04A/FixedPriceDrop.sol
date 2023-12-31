// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./PolyOneDrop.sol";
import "./IPolyOneDrop.sol";

/**
 * @title PolyOne Fixed Price Drop
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Implements the functionality required for Fixed Priced sales in the PolyOne contract ecosystem
 */
contract FixedPriceDrop is IPolyOneDrop, PolyOneDrop {
  constructor(address _polyOneCore) PolyOneDrop(_polyOneCore) {}

  function registerPurchaseIntent(
    uint256 _dropId,
    uint256 _tokenIndex,
    address, // _bidder
    uint256 _amount,
    bytes calldata
  ) external payable onlyPolyOneCore returns (bool, address, string memory, Royalties memory) {
    Drop memory drop = _validatePurchaseIntent(_dropId, _tokenIndex);
    if (_amount != drop.startingPrice) {
      revert InvalidPurchasePrice(_amount);
    }
    claimed[_dropId][_tokenIndex] = true;
    return (true, drop.collection, drop.baseTokenURI, drop.royalties);
  }

  function validateTokenClaim(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _claimant,
    bytes calldata
  ) external pure returns (address, string memory, Bid memory, Royalties memory) {
    revert InvalidClaim(_dropId, _tokenIndex, _claimant);
  }

  function listingActive(uint256 _dropId, uint256 _tokenIndex) external view returns (bool) {
    return
      !claimed[_dropId][_tokenIndex] &&
      PolyOneLibrary.isDateInPast(drops[_dropId].startDate) &&
      !PolyOneLibrary.isDateInPast(drops[_dropId].startDate + drops[_dropId].dropLength);
  }

  function listingEnded(uint256 _dropId, uint256 _tokenIndex) external view returns (bool) {
    return claimed[_dropId][_tokenIndex] || PolyOneLibrary.isDateInPast(drops[_dropId].startDate + drops[_dropId].dropLength);
  }

  function listingClaimed(uint256 _dropId, uint256 _tokenIndex) external view returns (bool) {
    return claimed[_dropId][_tokenIndex];
  }
}
