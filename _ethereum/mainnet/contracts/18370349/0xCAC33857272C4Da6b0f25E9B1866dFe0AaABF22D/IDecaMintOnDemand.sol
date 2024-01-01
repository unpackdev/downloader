// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./MintStructs.sol";

interface IDecaMintOnDemand {
  error TransferFailed();
  error CollectionMismatch();
  error PayoutMismatch();

  /**
   * @notice Creates a new collection via the factory, validates and executes the settlement. If successful, mints the NFT to the bidder.
   * @param collection Collection address.
   * @param bidder Bidder address.
   * @param creator Creator address.
   * @param payslips Payslips array.
   * @param bidId Bid id.
   * @param tokenId Token id.
   * @param price Price of the bid.
   */
  event BidSettled(
    address indexed collection,
    address indexed bidder,
    address indexed creator,
    MintStructs.Payslip[] payslips,
    bytes32 bidId,
    uint256 tokenId,
    uint256 price
  );
}
