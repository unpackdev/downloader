// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @dev ICoverPoolCallee interface for flash mint
 * @author crypto-pumpkin
 */
interface ICoverPoolCallee {
  /// @notice must return keccak256("ICoverPoolCallee.onFlashMint")
  function onFlashMint(
    address _sender,
    address _paymentToken,
    uint256 _paymentAmount,
    uint256 _amountOut,
    bytes calldata _data
  ) external returns (bytes32);
}