// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";

interface IRadRouter is IERC721Receiver {
  /**
   * @dev Emitted when a retail revenue split is updated for asset ledger `ledger`
   */
  event RetailRevenueSplitChange(address indexed ledger, address indexed stakeholder, uint256 share, uint256 totalStakeholders, uint256 totalSplit);

  /**
   * @dev Emitted when a resale revenue split is updated for asset ledger `ledger`
   */
  event ResaleRevenueSplitChange(address indexed ledger, address indexed stakeholder, uint256 share, uint256 totalStakeholders, uint256 totalSplit);

  /**
   * @dev Emitted when the minimum price of asset `assetId` is updated
   */
  event AssetMinPriceChange(address indexed ledger, uint256 indexed assetId, uint256 minPrice);

  /**
   * @dev Emitted when seller `seller` changes ownership for asset `assetId` in ledger `ledger` to or from this escrow. `escrowed` is true for deposits and false for withdrawals
   */
  event SellerEscrowChange(address indexed ledger, uint256 indexed assetId, address indexed seller, bool escrowed);

  /**
   * @dev Emitted when buyer `buyer` deposits or withdraws ETH from this escrow for asset `assetId` in ledger `ledger`. `escrowed` is true for deposits and false for withdrawals
   */
  event BuyerEscrowChange(address indexed ledger, uint256 indexed assetId, address indexed buyer, bool escrowed);

  /**
   * @dev Emitted when stakeholder `stakeholder` is paid out from a retail sale or resale
   */
  event StakeholderPayout(address indexed ledger, uint256 indexed assetId, address indexed stakeholder, uint256 payout, uint256 share, bool retail);

  /**
   * @dev Emitted when buyer `buyer` deposits or withdraws ETH from this escrow for asset `assetId` in ledger `ledger`. `escrowed` is true for deposits and false for withdrawals
   */
  event EscrowFulfill(address indexed ledger, uint256 indexed assetId, address seller, address buyer, uint256 value);

  /**
   * @dev Sets a stakeholder's revenue share for an asset ledger. If `retail` is true, sets retail revenue splits; otherwise sets resale revenue splits
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_stakeholder` cannot be the zero address.
   * - `_share` must be >= 0 and <= 100
   * - Revenue cannot be split more than 5 ways
   *
   * Emits a {RetailRevenueSplitChange|ResaleRevenueSplitChange} event.
   */
  function setRevenueSplit(address _ledger, address payable _stakeholder, uint256 _share, bool _retail) external returns (bool success);

  /**
   * @dev Returns the revenue share of `_stakeholder` for ledger `_ledger`
   *
   * See {setRevenueSplit}
   */
  function getRevenueSplit(address _ledger, address payable _stakeholder, bool _retail) external view returns (uint256 share);

  /**
   * @dev Sets multiple stakeholders' revenue shares for an asset ledger. Overwrites any existing revenue share. If `retail` is true, sets retail revenue splits; otherwise sets resale revenue splits
   * See {setRevenueSplit}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_stakeholders` cannot contain zero addresses.
   * - `_shares` must be >= 0 and <= 100
   * - Revenue cannot be split more than 5 ways
   *
   * Emits a {RetailRevenueSplitChange|ResaleRevenueSplitChange} event.
   */
  function setRevenueSplits(address _ledger, address payable[] calldata _stakeholders, uint256[] calldata _shares, bool _retail) external returns (bool success);

  /**
   * @dev For ledger `_ledger`, returns retail revenue stakeholders if `_retail` is true, otherwise returns resale revenue stakeholders.
   */
  function getRevenueStakeholders(address _ledger, bool _retail) external view returns (address[] memory stakeholders);

  /**
   * @dev Sets the minimum price for asset `_assetId`
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   * - `_minPrice` is in wei
   *
   * Emits a {AssetMinPriceChange} event.
   */
  function setAssetMinPrice(address _ledger, uint256 _assetId, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Sets a stakeholder's revenue share for an asset ledger. If `retail` is true, sets retail revenue splits; otherwise sets resale revenue splits.
   * Also sets the minimum price for asset `_assetId`
   * See {setAssetMinPrice | setRevenueSplits}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_stakeholder` cannot be the zero address.
   * - `_share` must be > 0 and <= 100
   * - Revenue cannot be split more than 5 ways
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   * - `_minPrice` is in wei
   *
   * Emits a {RetailRevenueSplitChange|ResaleRevenueSplitChange} event.
   */
  function setAssetMinPriceAndRevenueSplits(address _ledger, address payable[] calldata _stakeholders, uint256[] calldata _shares, bool _retail, uint256 _assetId, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Returns the minium price of asset `_assetId` in ledger `_ledger`
   *
   * See {setAssetMinPrice}
   */
  function getAssetMinPrice(address _ledger, uint256 _assetId) external view returns (uint256 minPrice);

  /**
   * @dev Transfers ownership of asset `_assetId` to this contract for escrow.
   * If buyer has already escrowed, triggers escrow fulfillment.
   * See {fulfill}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDeposit(address _ledger, uint256 _assetId) external returns (bool success);

  /**
   * @dev Transfers ownership of asset `_assetId` to this contract for escrow.
   * Sets asset min price to `_minPrice` if `_setMinPrice` is true. Reverts if `_setMinPrice` is true and buyer has already escrowed. Otherwise, if buyer has already escrowed, triggers escrow fulfillment.
   * See {fulfill | setAssetMinPrice}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   * - `_minPrice` is in wei
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDeposit(address _ledger, uint256 _assetId, bool _setMinPrice, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Transfers ownership of all assets `_assetIds` to this contract for escrow.
   * If any buyers have already escrowed, triggers escrow fulfillment for the respective asset.
   * See {fulfill}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDepositBatch(address _ledger, uint256[] calldata _assetIds) external returns (bool success);

  /**
   * @dev Transfers ownership of all assets `_assetIds` to this contract for escrow.
   * Sets each asset min price to `_minPrice` if `_setMinPrice` is true. Reverts if `_setMinPrice` is true and buyer has already escrowed. Otherwise, if any buyers have already escrowed, triggers escrow fulfillment for the respective asset.
   * See {fulfill | setAssetMinPrice}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_owner` must first approve this contract as an operator for ledger `_ledger`
   * - `_minPrice` is in wei
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowDepositBatch(address _ledger, uint256[] calldata _assetIds, bool _setMinPrice, uint256 _minPrice) external returns (bool success);

  /**
   * @dev Transfers ownership of asset `_assetId` from this contract for escrow back to seller.
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   *
   * Emits a {SellerEscrowChange} event.
   */
  function sellerEscrowWithdraw(address _ledger, uint256 _assetId) external returns (bool success);

  /**
   * @dev Accepts buyer's `msg.sender` funds into escrow for asset `_assetId` in ledger `_ledger`.
   * If seller has already escrowed, triggers escrow fulfillment.
   * See {fulfill}
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `msg.value` must be at least the seller's listed price
   * - `_assetId` in `ledger` cannot already have an escrowed buyer
   *
   * Emits a {BuyerEscrowChange} event.
   */
  function buyerEscrowDeposit(address _ledger, uint256 _assetId) external payable returns (bool success);

  /**
   * @dev Returns buyer's `msg.sender` funds back from escrow for asset `_assetId` in ledger `_ledger`.
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `msg.sender` must be the escrowed buyer for asset `_assetId` in ledger `_ledger`, asset owner, or Rad operator
   *
   * Emits a {BuyerEscrowChange} event.
   */
  function buyerEscrowWithdraw(address _ledger, uint256 _assetId) external returns (bool success);

  /**
   * @dev Returns the wallet address of the seller of asset `_assetId`
   *
   * See {sellerEscrowDeposit}
   */
  function getSellerWallet(address _ledger, uint256 _assetId) external view returns (address wallet);

  /**
   * @dev Returns the wallet address of the buyer of asset `_assetId`
   *
   * See {buyerEscrowDeposit}
   */
  function getBuyerWallet(address _ledger, uint256 _assetId) external view returns (address wallet);

  /**
   * @dev Returns the escrowed amount by the buyer of asset `_assetId`
   *
   * See {buyerEscrowDeposit}
   */
  function getBuyerDeposit(address _ledger, uint256 _assetId) external view returns (uint256 amount);

  /**
   * @dev Returns true if an asset has been sold for retail and will be considered resale moving forward
   */
  function getAssetIsResale(address _ledger, uint256 _assetId) external view returns (bool resale);

  /**
   * @dev Returns an array of all retailed asset IDs for ledger `_ledger`
   */
  function getRetailedAssets(address _ledger) external view returns (uint256[] memory assets);
}
