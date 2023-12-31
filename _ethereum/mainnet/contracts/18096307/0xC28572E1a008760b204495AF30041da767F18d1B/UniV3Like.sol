// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./IUniswapV3Pool.sol";
import "./IUniV3Like.sol";
import "./LibUniV3Like.sol";
import "./LibKitty.sol";
import "./LibWarp.sol";
import "./UniV3Callback.sol";

/**
 * A router for any Uniswap V3 fork
 *
 * The pools are not trusted to deliver the correct amount of tokens, so the router
 * verifies this.
 *
 * The pool addresses passed in as a parameter instead of being looked up from the factory. The caller
 * may use `getPair` on the factory to calculate pool addresses.
 */
contract UniV3Like is IUniV3Like {
  using SafeERC20 for IERC20;
  using Address for address;

  function uniswapV3LikeExactInputSingle(
    ExactInputSingleParams memory params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    bool isFromEth = params.tokenIn == address(0);
    bool isToEth = params.tokenOut == address(0);

    if (isFromEth) {
      IWETH weth = LibWarp.state().weth;

      params.tokenIn = address(weth);

      // From ETH
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }

      weth.deposit{value: msg.value}();
    }

    if (isToEth) {
      params.tokenOut = address(LibWarp.state().weth);
    }

    uint256 tokenOutBalancePrev = IERC20(params.tokenOut).balanceOf(address(this));

    LibUniV3Like.state().callbackPool = params.pool;

    bool zeroForOne = params.tokenIn < params.tokenOut;

    IUniV3Callback.SwapCallbackData memory callbackData = IUniV3Callback.SwapCallbackData({
      payer: isFromEth ? address(this) : msg.sender,
      tokenIn: params.tokenIn
    });

    if (zeroForOne) {
      (, int256 amountOutSigned) = IUniswapV3Pool(params.pool).swap(
        address(this),
        zeroForOne,
        int256(params.amountIn),
        LibUniV3Like.MIN_SQRT_RATIO,
        abi.encode(callbackData)
      );

      amountOut = uint256(-amountOutSigned);
    } else {
      (int256 amountOutSigned, ) = IUniswapV3Pool(params.pool).swap(
        address(this),
        zeroForOne,
        int256(params.amountIn),
        LibUniV3Like.MAX_SQRT_RATIO,
        abi.encode(callbackData)
      );

      amountOut = uint256(-amountOutSigned);
    }

    // TODO: Remove for production?
    require(LibUniV3Like.state().callbackPool == address(0), 'CALLBACK_POOL_NOT_RESET');

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    uint256 nextTokenOutBalance = IERC20(params.tokenOut).balanceOf(address(this));

    if (
      nextTokenOutBalance < tokenOutBalancePrev ||
      nextTokenOutBalance < tokenOutBalancePrev + amountOut
    ) {
      revert InsufficienTokensDelivered();
    }

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibKitty.calculateAndRegisterFee(
      params.partner,
      params.tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (isToEth) {
      // TODO: This is read twice. Compare gas usage
      // Unwrap WETH
      LibWarp.state().weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);
    }
  }

  function uniswapV3LikeExactInput(
    ExactInputParams memory params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    uint256 poolLength = params.pools.length;
    bool isFromEth = params.tokens[0] == address(0);
    bool isToEth = params.tokens[poolLength] == address(0);
    address payer = isFromEth ? address(this) : msg.sender;

    if (isFromEth) {
      IWETH weth = LibWarp.state().weth;

      params.tokens[0] = address(weth);

      // From ETH
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }

      weth.deposit{value: msg.value}();
    }

    if (isToEth) {
      params.tokens[poolLength] = address(LibWarp.state().weth);
    }

    uint256 tokenOutBalancePrev = IERC20(params.tokens[poolLength]).balanceOf(address(this));

    IUniV3Callback.SwapCallbackData memory callbackData;

    amountOut = params.amountIn;

    for (uint index; index < poolLength; ) {
      uint256 indexPlusOne;

      unchecked {
        indexPlusOne = index + 1;
      }

      bool zeroForOne = params.tokens[index] < params.tokens[indexPlusOne];

      LibUniV3Like.state().callbackPool = params.pools[index];

      callbackData.payer = payer;
      callbackData.tokenIn = params.tokens[index];

      if (zeroForOne) {
        (, int256 amountOutSigned) = IUniswapV3Pool(params.pools[index]).swap(
          address(this),
          zeroForOne,
          int256(amountOut),
          LibUniV3Like.MIN_SQRT_RATIO,
          abi.encode(callbackData)
        );

        amountOut = uint256(-amountOutSigned);
      } else {
        (int256 amountOutSigned, ) = IUniswapV3Pool(params.pools[index]).swap(
          address(this),
          zeroForOne,
          int256(amountOut),
          LibUniV3Like.MAX_SQRT_RATIO,
          abi.encode(callbackData)
        );

        amountOut = uint256(-amountOutSigned);
      }

      // TODO: Remove for production?
      require(LibUniV3Like.state().callbackPool == address(0), 'CALLBACK_POOL_NOT_RESET');

      // TODO: Compare check-and-set with set
      payer = address(this);

      index = indexPlusOne;
    }

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    uint256 nextTokenOutBalance = IERC20(params.tokens[poolLength]).balanceOf(address(this));

    if (
      nextTokenOutBalance < tokenOutBalancePrev ||
      nextTokenOutBalance < tokenOutBalancePrev + amountOut
    ) {
      revert InsufficienTokensDelivered();
    }

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibKitty.calculateAndRegisterFee(
      params.partner,
      params.tokens[poolLength],
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (isToEth) {
      // Unwrap WETH
      LibWarp.state().weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(params.tokens[poolLength]).safeTransfer(params.recipient, amountOut);
    }
  }
}
