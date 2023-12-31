// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ICurve.sol";
import "./LibKitty.sol";
import "./LibWarp.sol";
import "./LibCurve.sol";

/**
 * Swaps for Curve pools
 *
 * The pools are not trusted to deliver the correct amount of tokens, so the router
 * verifies this.
 */
contract Curve is ICurve {
  using SafeERC20 for IERC20;
  using Address for address;

  function curveExactInputSingle(
    ExactInputSingleParams memory params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    bool isToEth = params.tokenOut == address(0);

    uint256 tokenOutBalancePrev = isToEth
      ? address(this).balance
      : IERC20(params.tokenOut).balanceOf(address(this));

    if (params.tokenIn != address(0)) {
      // TODO: Is this necessary to support USDT?
      IERC20(params.tokenIn).forceApprove(params.pool, params.amountIn);

      IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
    }

    LibCurve.exchange({
      kind: params.kind,
      underlying: params.underlying,
      pool: params.pool,
      eth: msg.value,
      i: params.tokenIndexIn,
      j: params.tokenIndexOut,
      // NOTE: `params.amountIn` is not verified to equal `msg.value`
      dx: params.amountIn,
      // NOTE: There is no need to set a min out since the balance is verified
      min_dy: 0
    });

    uint256 nextTokenOutBalance = isToEth
      ? address(this).balance
      : IERC20(params.tokenOut).balanceOf(address(this));

    amountOut = nextTokenOutBalance - tokenOutBalancePrev;

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    amountOut = LibKitty.calculateAndRegisterFee(
      params.partner,
      params.tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (isToEth) {
      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);
    }
  }
}
