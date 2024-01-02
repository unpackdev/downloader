// SPDX-License-Identifier: MIT

/**
 * Author: Lambdalf the White
 */

pragma solidity ^0.8.17;

import "./IERC2981.sol";
import "./Initializable.sol";

abstract contract ERC2981Initializable is IERC2981, Initializable {
  // **************************************
  // *****         DATA TYPES         *****
  // **************************************
  /// @dev A structure representing royalties
  struct RoyaltyData {
    address recipient;
    uint96 rate;
  }
  // **************************************

  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
  /// @dev Royalty rate is stored out of 10,000 instead of a percentage
  ///   to allow for up to two digits below the unit such as 2.5% or 1.25%.
  uint256 public constant ROYALTY_BASE = 10_000;
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
  /// @dev Represents the royalties on each sale on secondary markets.
  ///   Set rate to 0 to have no royalties.
  RoyaltyData private _royaltyData;
  // **************************************

  function _init_ERC2981(address royaltyRecipient_, uint96 royaltyRate_) internal onlyInitializing {
    _setRoyaltyInfo(royaltyRecipient_, royaltyRate_);
  }

  // **************************************
  // *****            VIEW            *****
  // **************************************
  /// @dev Called with the sale price to determine how much royalty is owed and to whom.
  ///
  /// @param tokenId_ identifier of the NFT being referenced
  /// @param salePrice_ the sale price of the token sold
  ///
  /// @return receiver the address receiving the royalties
  /// @return royaltyAmount the royalty payment amount
  /* solhint-disable no-unused-vars */
  function royaltyInfo(
    uint256 tokenId_,
    uint256 salePrice_
  ) public view virtual override returns (address receiver, uint256 royaltyAmount) {
    RoyaltyData memory _data_ = _royaltyData;
    if (salePrice_ == 0 || _data_.rate == 0 || _data_.recipient == address(0)) {
      return (address(0), 0);
    }
    uint256 _royaltyAmount_ = _data_.rate * salePrice_ / ROYALTY_BASE;
    return (_data_.recipient, _royaltyAmount_);
  }
  /* solhint-enable no-unused-vars */
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
  /// @dev Sets the royalty rate to `newRoyaltyRate_` and the royalty recipient to `newRoyaltyRecipient_`.
  ///
  /// @param newRoyaltyRecipient_ the address that will receive royalty payments
  /// @param newRoyaltyRate_ the percentage of the sale price that will be taken off as royalties,
  ///   expressed in Basis Points (100 BP = 1%)
  ///
  /// Requirements:
  ///
  /// - `newRoyaltyRate_` cannot be higher than {ROYALTY_BASE};
  function _setRoyaltyInfo(address newRoyaltyRecipient_, uint96 newRoyaltyRate_) internal virtual {
    if (newRoyaltyRate_ > ROYALTY_BASE) {
      revert IERC2981_INVALID_ROYALTIES();
    }
    _royaltyData = RoyaltyData(newRoyaltyRecipient_, newRoyaltyRate_);
  }
  // **************************************
}
