// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

// Imports
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
import "./IWETH9.sol";
import "./IERC20.sol";

/**
 * This library provides routines for handling trading via Uniswap V3 exchange.
 */
library UniswapV3Trading {
  // Ethereum mainnet address of the UniswapV3Router
  address constant internal UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  // Ethereum mainnet address of the Wrapped Ether
  address constant internal WETH9_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  // Flags bit mask bit 0: equals 1 if first token in path is Ether (WETH wrapping/unwrapping is necessary).
  uint8 constant internal FLAGS_FIRST_TOKEN_IS_ETHER = (1 << 0);
  // Flags bit mask bit 1: equals 1 if the last token in path is Ether (WETH wrapping/unwrapping is necessary).
  uint8 constant internal FLAGS_LAST_TOKEN_IS_ETHER = (1 << 1);
  // Flags bit mask bit 2: equals 1 for "exact in" swaps, 0 for "exact out" swaps.
  uint8 constant internal FLAGS_IS_EXACT_IN = (1 << 2);

  /**
   * A method which calls UniswapV3Router and (optionally) WETH9 to actually execute the trade.
   *
   * Paths are represented in UniswapV3 Periphery format - 20-byte token contract addresses interspersed with 3-byte fees.
   * For "exact in" swaps the paths are non-reversed (first token is "in" token and last token is "out" token) and reversed for "exact out" swaps.
   * If one swap side amount is fixed as "exact", the other side acts as an upper/lower bound to permitted slippage.
   *
   * @param path token exchange path in the aforementioned format
   * @param flags a 3-bit OR'ed bitmask of any subset of {FLAGS_FIRST_TOKEN_IS_ETHER, FLAGS_LAST_TOKEN_IS_ETHER, FLAGS_IS_EXACT_IN}
   * @param amountIn the "in" token amount (either exact or upper bound, depending on flags)
   * @param amountOut the "out" token amount (either exact or lower bound, depending on flags)
   *
   * @return success a flag indicating whether a swap was performed successfully
   * @return actualIn actually consumed amount of the "in" token
   * @return actualOut actually obtained amount of the "out" token
   * @return tokenIn contract address of the "in" token
   * @return tokenOut contract address of the "out" token
   * @return takeFeeInEther a flag indicating whether to take the fee in Ether
   */
  function performTrade(bytes memory path, uint8 flags, uint256 amountIn, uint256 amountOut) internal returns (bool success, uint256 actualIn, uint256 actualOut, address tokenIn, address tokenOut, bool takeFeeInEther) {
    takeFeeInEther = false;

    // "In" token is Ether - wrap it as WETH
    if ((flags & FLAGS_FIRST_TOKEN_IS_ETHER) == FLAGS_FIRST_TOKEN_IS_ETHER) {
      (success,) = WETH9_ADDRESS.call{ value: amountIn }(abi.encodeWithSelector(IWETH9.deposit.selector));

      if (!success) {
        return (false, 0, 0, address(0), address(0), false);
      }
    }

    // Dispatch between "exact in" and "exact out" swaps; note the path encoding difference.
    if ((flags & FLAGS_IS_EXACT_IN) == FLAGS_IS_EXACT_IN) {
      (success, actualOut, tokenIn, tokenOut) = UniswapV3Trading.performExactInTrade(path, amountIn, amountOut);
      actualIn = amountIn;
    } else {
      (success, actualIn, tokenIn, tokenOut) = UniswapV3Trading.performExactOutTrade(path, amountIn, amountOut);
      actualOut = amountOut;
    }

    // Handle failure
    if (!success) {
      return (false, 0, 0, address(0), address(0), false);
    }

    // Clear approvals if leftover is present
    if (actualIn < amountIn) {
      TransferHelper.safeApprove(tokenIn, UNISWAP_V3_ROUTER_ADDRESS, 0);

      // If there is leftover WETH, unwrap it to Ether
      if ((flags & FLAGS_FIRST_TOKEN_IS_ETHER) == FLAGS_FIRST_TOKEN_IS_ETHER) {
        IWETH9(WETH9_ADDRESS).withdraw(amountIn - actualIn);
      }
    }

    // If the "out" token is Ether, unwrap WETH.
    if ((flags & FLAGS_LAST_TOKEN_IS_ETHER) == FLAGS_LAST_TOKEN_IS_ETHER) {
      takeFeeInEther = true;
      IWETH9(WETH9_ADDRESS).withdraw(actualOut);
    }
  }

  /**
   * A helper to perform an "exact in" trade.
   *
   * @param path token exchange path in direct UniswapV3 format (first token is "in" token, last token is "out" token)
   * @param amountIn exact "in" amount to spend
   * @param amountOutMinimum lower bound on "out" amount (to limit slippage)
   *
   * @return success a flag indicating whether a swap was performed successfully
   * @return amount actually obtained amount of the "out" token
   * @return tokenIn contract address of the "in" token
   * @return tokenOut contract address of the "out" token
   */
  function performExactInTrade(bytes memory path, uint256 amountIn, uint256 amountOutMinimum) internal returns (bool success, uint256 amount, address tokenIn, address tokenOut) {
    // Extract "endpoints" from direct path
    // Right 96 bit shift is cheap way to get from big-endian uint256 to a 160 bit address at the same offset
    uint256 length = path.length - 20;

    assembly {
      tokenIn := shr(96, mload(add(path, 0x20)))
      tokenOut := shr(96, mload(add(add(path, 0x20), length)))
    }

    // Approve exact input spend
    TransferHelper.safeApprove(tokenIn, UNISWAP_V3_ROUTER_ADDRESS, amountIn);

    // Perform the swap using UniswapV3 SwapRouter
    ISwapRouter swapRouter = ISwapRouter(UNISWAP_V3_ROUTER_ADDRESS);

    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: path,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: amountOutMinimum
    });

    // Catch the error, if any - do not revert.
    try swapRouter.exactInput(params) returns (uint256 value) {
      success = true;
      amount = value;
    } catch {
      success = false;
      amount = 0;
    }
  }

  /**
   * A helper to perform an "exact out" trade.
   *
   * @param path token exchange path in reversed UniswapV3 format (first token is "out" token, last token is "in" token)
   * @param amountInMaximum upper bound on "in" amount to spend (to limit slippage)
   * @param amountOut exact "out" amount to obtain
   *
   * @return success a flag indicating whether a swap was performed successfully
   * @return amount actually consumed amount of the "in" token
   * @return tokenIn contract address of the "in" token
   * @return tokenOut contract address of the "out" token
   */
  function performExactOutTrade(bytes memory path, uint256 amountInMaximum, uint256 amountOut) internal returns (bool success, uint256 amount, address tokenIn, address tokenOut) {
    // Extract "endpoints" from direct path
    // Right 96 bit shift is cheap way to get from big-endian uint256 to a 160 bit address at the same offset
    uint256 length = path.length - 20;

    assembly {
      tokenOut := shr(96, mload(add(path, 0x20)))
      tokenIn := shr(96, mload(add(add(path, 0x20), length)))
    }

    // Approve "input" spend upper bound
    TransferHelper.safeApprove(tokenIn, UNISWAP_V3_ROUTER_ADDRESS, amountInMaximum);

    // Perform the swap using UniswapV3 SwapRouter
    ISwapRouter swapRouter = ISwapRouter(UNISWAP_V3_ROUTER_ADDRESS);

    ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
      path: path,
      recipient: address(this),
      deadline: block.timestamp,
      amountOut: amountOut,
      amountInMaximum: amountInMaximum
    });

    // Catch the error, if any - do not revert.
    try swapRouter.exactOutput(params) returns (uint256 value) {
      success = true;
      amount = value;
    } catch {
      success = false;
      amount = 0;
    }
  }
}
