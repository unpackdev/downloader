// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./IUniswapV3Pool.sol";
import "./IUniV3Like.sol";
import "./LibUniV3Like.sol";
import "./LibStarVault.sol";
import "./LibWarp.sol";
import "./IPermit2.sol";
import "./IAllowanceTransfer.sol";
import "./PermitParams.sol";

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

  function uniswapV3LikeExactInputSingleInternal(
    ExactInputSingleParams calldata params,
    uint256 usePermit
  ) internal returns (uint256 amountOut) {
    bool isFromEth = params.tokenIn == address(0);
    address tokenIn = isFromEth ? address(LibWarp.state().weth) : params.tokenIn;

    address tokenOut = params.tokenOut == address(0)
      ? address(LibWarp.state().weth)
      : params.tokenOut;

    uint256 tokenOutBalancePrev = IERC20(tokenOut).balanceOf(address(this));

    bool zeroForOne = tokenIn < tokenOut;

    LibUniV3Like.beforeCallback(
      LibUniV3Like.CallbackState({
        payer: isFromEth ? address(this) : msg.sender,
        token: tokenIn,
        amount: params.amountIn,
        usePermit: usePermit
      })
    );

    if (zeroForOne) {
      (, int256 amountOutSigned) = IUniswapV3Pool(params.pool).swap(
        address(this),
        zeroForOne,
        int256(params.amountIn),
        LibUniV3Like.MIN_SQRT_RATIO,
        ''
      );

      amountOut = uint256(-amountOutSigned);
    } else {
      (int256 amountOutSigned, ) = IUniswapV3Pool(params.pool).swap(
        address(this),
        zeroForOne,
        int256(params.amountIn),
        LibUniV3Like.MAX_SQRT_RATIO,
        ''
      );

      amountOut = uint256(-amountOutSigned);
    }

    LibUniV3Like.afterCallback();

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    uint256 nextTokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    if (
      nextTokenOutBalance < tokenOutBalancePrev ||
      nextTokenOutBalance < tokenOutBalancePrev + amountOut
    ) {
      revert InsufficienTokensDelivered();
    }

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (params.tokenOut == address(0)) {
      // To ETH, unwrap WETH
      // TODO: This is read twice. Compare gas usage
      LibWarp.state().weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(tokenOut).safeTransfer(params.recipient, amountOut);
    }

    emit LibWarp.Warp(params.partner, params.tokenIn, params.tokenOut, params.amountIn, amountOut);
  }

  function uniswapV3LikeExactInputSingle(
    ExactInputSingleParams calldata params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    if (params.tokenIn == address(0)) {
      // From ETH, wrap it
      IWETH weth = LibWarp.state().weth;

      // From ETH
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }

      weth.deposit{value: msg.value}();
    }

    return uniswapV3LikeExactInputSingleInternal(params, 0);
  }

  function uniswapV3LikeExactInputSinglePermit(
    ExactInputSingleParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut) {
    // Permit this contract to move tokens from the sender. The actual transfer happens inside UniV3Callback.
    LibWarp.state().permit2.permit(
      msg.sender,
      IAllowanceTransfer.PermitSingle(
        IAllowanceTransfer.PermitDetails({
          token: params.tokenIn,
          amount: (uint160)(params.amountIn),
          expiration: params.deadline,
          nonce: (uint48)(permit.nonce)
        }),
        address(this),
        params.deadline
      ),
      permit.signature
    );

    return uniswapV3LikeExactInputSingleInternal(params, 1);
  }

  function uniswapV3LikeExactInputInternal(
    ExactInputParams calldata params,
    uint256 usePermit
  ) internal returns (uint256 amountOut) {
    uint256 poolLength = params.pools.length;
    address payer = params.tokens[0] == address(0) ? address(this) : msg.sender;
    address[] memory tokens = params.tokens;

    if (params.tokens[0] == address(0)) {
      tokens[0] = address(LibWarp.state().weth);
    }

    if (params.tokens[poolLength] == address(0)) {
      tokens[poolLength] = address(LibWarp.state().weth);
    }

    uint256 tokenOutBalancePrev = IERC20(tokens[poolLength]).balanceOf(address(this));

    amountOut = params.amountIn;

    for (uint index; index < poolLength; ) {
      uint256 indexPlusOne;

      unchecked {
        indexPlusOne = index + 1;
      }

      bool zeroForOne = tokens[index] < tokens[indexPlusOne];

      LibUniV3Like.beforeCallback(
        LibUniV3Like.CallbackState({
          payer: payer,
          token: tokens[index],
          amount: amountOut,
          usePermit: usePermit
        })
      );

      if (zeroForOne) {
        (, int256 amountOutSigned) = IUniswapV3Pool(params.pools[index]).swap(
          address(this),
          zeroForOne,
          int256(amountOut),
          LibUniV3Like.MIN_SQRT_RATIO,
          ''
        );

        amountOut = uint256(-amountOutSigned);
      } else {
        (int256 amountOutSigned, ) = IUniswapV3Pool(params.pools[index]).swap(
          address(this),
          zeroForOne,
          int256(amountOut),
          LibUniV3Like.MAX_SQRT_RATIO,
          ''
        );

        amountOut = uint256(-amountOutSigned);
      }

      LibUniV3Like.afterCallback();

      // TODO: Compare check-and-set with set
      payer = address(this);

      index = indexPlusOne;
    }

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    uint256 nextTokenOutBalance = IERC20(tokens[poolLength]).balanceOf(address(this));

    if (
      nextTokenOutBalance < tokenOutBalancePrev ||
      nextTokenOutBalance < tokenOutBalancePrev + amountOut
    ) {
      revert InsufficienTokensDelivered();
    }

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      tokens[poolLength],
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (params.tokens[poolLength] == address(0)) {
      // To ETH, unwrap
      LibWarp.state().weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(tokens[poolLength]).safeTransfer(params.recipient, amountOut);
    }

    emit LibWarp.Warp(
      params.partner,
      params.tokens[0],
      params.tokens[poolLength],
      params.amountIn,
      amountOut
    );
  }

  function uniswapV3LikeExactInput(
    ExactInputParams calldata params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    if (params.tokens[0] == address(0)) {
      // From ETH, wrap it
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }

      LibWarp.state().weth.deposit{value: msg.value}();
    }

    return uniswapV3LikeExactInputInternal(params, 0);
  }

  function uniswapV3LikeExactInputPermit(
    ExactInputParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut) {
    // Permit this contract to move tokens from the sender. The actual transfer happens inside UniV3Callback.
    LibWarp.state().permit2.permit(
      msg.sender,
      IAllowanceTransfer.PermitSingle(
        IAllowanceTransfer.PermitDetails({
          token: params.tokens[0],
          amount: (uint160)(params.amountIn),
          expiration: params.deadline,
          nonce: (uint48)(permit.nonce)
        }),
        address(this),
        (uint256)(params.deadline)
      ),
      permit.signature
    );

    return uniswapV3LikeExactInputInternal(params, 1);
  }
}
