// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

// Imports
import "./TransferHelper.sol";
import "./UniswapV3Trading.sol";

/**
 * This is an abstract contract handling interaction with different DEXs ("brokers").
 *
 * It primary purpose is to properly route trading request to the implementation,
 * receive the result and log corresponding events.
 *
 * It also takes care of gathering trade fees: these are forced to never exceed 3%,
 * but can be as low as 0 (depending on amountFee) parameter.
 */
abstract contract Trading {
  // Constants
  uint8 constant internal UNISWAP_V3_BROKER = 0x1;
  uint16 constant internal MAX_FEE_BASE_1000 = 30;

  /**
   * An event emitted on a successful trade. All values are actually traded amounts.
   *
   * @param tradeId a unique identifier of the trade for SlickSwap internal bookkeeping
   * @param amountIn actually spent source token amount
   * @param amountOut actually obtained destination token amount
   * @param amountFee actually spent fee
   */
  event Trade(uint256 indexed tradeId, uint256 amountIn, uint256 amountOut, uint256 amountFee);

  /**
   * An event emitted on a failed trade. Various reasons include, but are not limited to:
   *  - insufficient balances
   *  - low liquidity
   *  - slippage overshoot (frontrunning)
   *
   * @param tradeId a unique identifier of the trade for SlickSwap internal bookkeeping
   */
  event TradeFailed(uint256 indexed tradeId);

  /**
   * Perform a trade.
   *
   * @param tradeId a unique identifier of the trade for SlickSwap internal bookkeeping
   * @param broker the type of the broker (the only supported value is 1, meaning Uniswap V3)
   * @param path token exchange path, in the format of a specific broker (see UniswapV3Trading for example)
   * @param flags a bitmask representing trade settings of a specific broker (see UniswapV3Trading for example)
   * @param amountIn amount of the "source" token to trade
   * @param amountOut amount of the "destination" token to trade
   * @param amountFee amount of the "destination" taken by SlickSwap as a fee. Enforced to be less than 3%.
   */
  function _trade(uint256 tradeId, uint8 broker, bytes memory path, uint8 flags, uint256 amountIn, uint256 amountOut, uint256 amountFee, address feeRecipient) internal returns (bool success) {
    // Invoke the implementation dispatch
    (bool tradeSuccess, uint256 actualIn, uint256 actualOut, uint256 actualFee) = _performTrade(broker, path, flags, amountIn, amountOut, amountFee, feeRecipient);

    // Emit events
    if (tradeSuccess) {
      emit Trade(tradeId, actualIn, actualOut, actualFee);
    } else {
      emit TradeFailed(tradeId);
    }

    return tradeSuccess;
  }

  /**
   * The actual trading logic implementation.
   */
  function _performTrade(uint8 broker, bytes memory path, uint8 flags, uint256 amountIn, uint256 amountOut, uint256 amountFee, address feeRecipient) internal returns (bool success, uint256 actualIn, uint256 actualOut, uint256 actualFee) {
    // Uniswap V3
    if (broker == UNISWAP_V3_BROKER) {
      address tokenIn;
      address tokenOut;
      bool takeFeeInEther;

      // Perform the trade
      (success, actualIn, actualOut, tokenIn, tokenOut, takeFeeInEther) = UniswapV3Trading.performTrade(path, flags, amountIn, amountOut);

      if (!success) {
        return (false, 0, 0, 0);
      }

      // Important: limit fee to 3% of the actual output amount
      uint256 maximumFee = actualOut * MAX_FEE_BASE_1000 / 1000;
      actualFee = amountFee > maximumFee ? maximumFee : amountFee;

      // Collect the fee
      if (actualFee > 0) {
        if (takeFeeInEther) {
          (bool transferSuccess,) = feeRecipient.call{ value: actualFee }("");
          require(transferSuccess, "Ether fee capture failed");
        } else {
          TransferHelper.safeTransfer(tokenOut, feeRecipient, actualFee);
        }
      }
    } else {
      // Revert on unknown broker
      require(false, "Unknown broker id");
    }
  }
}
