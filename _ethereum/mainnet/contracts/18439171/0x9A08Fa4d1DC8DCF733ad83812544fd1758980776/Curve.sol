// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ICurve.sol";
import "./LibStarVault.sol";
import "./LibWarp.sol";
import "./LibCurve.sol";
import "./IPermit2.sol";
import "./IAllowanceTransfer.sol";
import "./PermitParams.sol";

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
    ExactInputSingleParams memory params,
    PermitParams calldata permit
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    bool isToEth = params.tokenOut == address(0);

    uint256 tokenOutBalancePrev = isToEth
      ? address(this).balance
      : IERC20(params.tokenOut).balanceOf(address(this));

    if (params.tokenIn != address(0)) {
      // TODO: Is this necessary to support USDT? @jflint256: Yes, I think so.
      IERC20(params.tokenIn).forceApprove(params.pool, params.amountIn);

      // Permit tokens / set allowance
      LibWarp.state().permit2.permit(
        msg.sender,
        IAllowanceTransfer.PermitSingle({
          details: IAllowanceTransfer.PermitDetails({
            token: params.tokenIn,
            amount: (uint160)(params.amountIn),
            expiration: (uint48)(params.deadline),
            nonce: (uint48)(permit.nonce)
          }),
          spender: address(this),
          sigDeadline: (uint256)(params.deadline)
        }),
        permit.signature
      );

      // Transfer tokens from msg.sender to address(this)
      LibWarp.state().permit2.transferFrom(
        msg.sender,
        address(this),
        (uint160)(params.amountIn),
        params.tokenIn
      );
    }

    LibCurve.exchange({
      kind: params.kind,
      underlying: params.underlying,
      pool: params.pool,
      eth: msg.value,
      useEth: params.useEth,
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

    amountOut = LibStarVault.calculateAndRegisterFee(
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

    emit LibWarp.Warp(params.partner, params.tokenIn, params.tokenOut, params.amountIn, amountOut);
  }
}
