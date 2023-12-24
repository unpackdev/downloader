// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IRFQ {
  struct OrderRFQ {
    // lowest 64 bits is the order id, next 64 bits is the expiration timestamp
    // highest bit is unwrap WETH flag which is set on taker's side
    // [unwrap eth(1 bit) | unused (127 bits) | expiration timestamp(64 bits) | orderId (64 bits)]
    uint256 info;
    address makerAsset;
    address takerAsset;
    address maker;
    address allowedSender; // null address on public orders
    uint256 makingAmount;
    uint256 takingAmount;
  }

  /// @notice Fills an order's quote, either fully or partially
  /// @dev Funds will be sent to msg.sender
  /// @param order Order quote to fill
  /// @param signature Signature to confirm quote ownership
  /// @param makingAmount Maker amount
  /// @param takingAmount Taker amount
  function fillOrderRFQ(
    OrderRFQ memory order,
    bytes calldata signature,
    uint256 makingAmount,
    uint256 takingAmount
  )
    external
    payable
    returns (
      uint256, /* actualmakingAmount */
      uint256 /* actualtakingAmount */
    );

  /// @notice Main function for fulfilling orders
  /// @param order Order quote to fill
  /// @param signature Signature to confirm quote ownership
  /// @param makingAmount Maker amount
  /// @param takingAmount Taker amount
  /// @param target Address that will receive swapped funds
  function fillOrderRFQTo(
    OrderRFQ memory order,
    bytes calldata signature,
    uint256 makingAmount,
    uint256 takingAmount,
    address payable target
  )
    external
    payable
    returns (
      uint256, /* actualmakingAmount */
      uint256 /* actualtakingAmount */
    );
}
