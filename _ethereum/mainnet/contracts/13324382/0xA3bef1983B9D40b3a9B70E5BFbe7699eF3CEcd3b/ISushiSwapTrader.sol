// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface ISushiSwapTrader {
  /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
  function updateSlippageNumerator(uint24 slippageNumerator_) external;

  /// @notice Swaps all WETH held in this contract for BIOS and sends to the kernel
  /// @return Bool indicating whether the trade succeeded
  function biosBuyBack() external returns (bool);

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param recipient The address of the token out recipient
  /// @param amountIn The exact amount of the input to swap
  /// @param amountOutMin The minimum amount of tokenOut to receive from the swap
  /// @return bool Indicates whether the swap succeeded
  function swapExactInput(
    address tokenIn,
    address tokenOut,
    address recipient,
    uint256 amountIn,
    uint256 amountOutMin
  ) external returns (bool);
}
