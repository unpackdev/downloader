// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniV2Router.sol";
import "./LibUniV2Router.sol";
import "./LibStarVault.sol";
import "./LibWarp.sol";
import "./IUniswapV2Pair.sol";
import "./IPermit2.sol";
import "./IAllowanceTransfer.sol";
import "./PermitParams.sol";

contract UniV2RouterFacet is IUniV2Router {
  using SafeERC20 for IERC20;
  using Address for address;

  /**
   * NOTE: The tokens must already have been transferred to the pool
   */
  function uniswapV2ExactInputSingleInternal(
    ExactInputSingleParams calldata params,
    address pair
  ) internal returns (uint256 amountOut) {
    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    address tokenIn = params.tokenIn == address(0) ? address(s.weth) : params.tokenIn;
    address tokenOut = params.tokenOut == address(0) ? address(s.weth) : params.tokenOut;

    (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(pair).getReserves();

    if (tokenIn > tokenOut) {
      (reserveIn, reserveOut) = (reserveOut, reserveIn);
    }

    unchecked {
      amountOut =
        ((params.amountIn * 997) * reserveOut) /
        ((reserveIn * 1000) + (params.amountIn * 997));
    }

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippage)) {
      revert InsufficientOutputAmount();
    }

    bool zeroForOne = tokenIn < tokenOut ? true : false;

    IUniswapV2Pair(pair).swap(
      zeroForOne ? 0 : amountOut,
      zeroForOne ? amountOut : 0,
      address(this),
      ''
    );

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (amountOut == 0) {
      revert ZeroAmountOut();
    }

    if (params.tokenOut == address(0)) {
      // Unwrap WETH
      s.weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(tokenOut).safeTransfer(params.recipient, amountOut);
    }

    emit LibWarp.Warp(params.partner, params.tokenIn, params.tokenOut, params.amountIn, amountOut);
  }

  function uniswapV2ExactInputSingle(
    ExactInputSingleParams calldata params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    address pair = LibUniV2Router.pairFor(
      s.uniswapV2Factory,
      params.tokenIn == address(0) ? address(s.weth) : params.tokenIn,
      params.tokenOut == address(0) ? address(s.weth) : params.tokenOut
    );

    if (params.tokenIn == address(0)) {
      // From ETH
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }

      s.weth.deposit{value: msg.value}();

      // Transfer tokens to the pool
      IERC20(address(s.weth)).safeTransfer(pair, params.amountIn);
    } else {
      IERC20(params.tokenIn).safeTransferFrom(msg.sender, pair, params.amountIn);
    }

    return uniswapV2ExactInputSingleInternal(params, pair);
  }

  function uniswapV2ExactInputSinglePermit(
    ExactInputSingleParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut) {
    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    address pair = LibUniV2Router.pairFor(
      s.uniswapV2Factory,
      params.tokenIn,
      params.tokenOut == address(0) ? address(s.weth) : params.tokenOut
    );

    // Permit tokens / set allowance
    s.permit2.permit(
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

    // Transfer tokens from msg.sender to the pool
    s.permit2.transferFrom(msg.sender, pair, (uint160)(params.amountIn), params.tokenIn);

    return uniswapV2ExactInputSingleInternal(params, pair);
  }

  /**
   * NOTE: The tokens must already have been transferred to the first pool
   *
   * The path should be rewritten so address(0) is replaced by the WETH address
   */
  function uniswapV2ExactInputInternal(
    ExactInputParams calldata params,
    address[] memory path,
    address[] memory pairs,
    uint256[] memory amounts
  ) internal returns (uint256 amountOut) {
    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    uint256 pathLengthMinusOne = params.path.length - 1;

    // Enforce minimum amount/max slippage
    if (amounts[amounts.length - 1] < LibWarp.applySlippage(params.amountOut, params.slippage)) {
      revert InsufficientOutputAmount();
    }

    // https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol
    for (uint index; index < pathLengthMinusOne; ) {
      uint256 indexPlusOne = index + 1;
      bool zeroForOne = path[index] < path[indexPlusOne] ? true : false;
      address to = index < path.length - 2 ? pairs[indexPlusOne] : address(this);

      IUniswapV2Pair(pairs[index]).swap(
        zeroForOne ? 0 : amounts[indexPlusOne],
        zeroForOne ? amounts[indexPlusOne] : 0,
        to,
        ''
      );

      unchecked {
        ++index;
      }
    }

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      path[pathLengthMinusOne],
      params.feeBps,
      params.amountOut,
      amounts[pathLengthMinusOne]
    );

    if (amountOut == 0) {
      revert ZeroAmountOut();
    }

    if (params.path[pathLengthMinusOne] == address(0)) {
      // To ETH. Unwrap WETH
      s.weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert EthTransferFailed();
      }
    } else {
      IERC20(path[pathLengthMinusOne]).safeTransfer(params.recipient, amountOut);
    }

    emit LibWarp.Warp(
      params.partner,
      params.path[0],
      params.path[pathLengthMinusOne],
      params.amountIn,
      amountOut
    );
  }

  function uniswapV2ExactInput(
    ExactInputParams calldata params
  ) external payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    uint256 pathLengthMinusOne = params.path.length - 1;
    address[] memory path = params.path;

    if (params.path[0] == address(0)) {
      // From ETH
      path[0] = address(s.weth);
    }

    if (params.path[pathLengthMinusOne] == address(0)) {
      // To ETH
      path[pathLengthMinusOne] = address(s.weth);
    }

    (address[] memory pairs, uint256[] memory amounts) = LibUniV2Router.getPairsAndAmountsFromPath(
      s.uniswapV2Factory,
      params.amountIn,
      path
    );

    // Enforce minimum amount/max slippage
    if (amounts[amounts.length - 1] < LibWarp.applySlippage(params.amountOut, params.slippage)) {
      revert InsufficientOutputAmount();
    }

    if (params.path[0] == address(0)) {
      // From ETH
      if (msg.value != params.amountIn) {
        revert IncorrectEthValue();
      }

      s.weth.deposit{value: msg.value}();

      // Transfer WETH tokens to the first pool
      IERC20(path[0]).safeTransfer(pairs[0], params.amountIn);
    } else {
      IERC20(path[0]).safeTransferFrom(msg.sender, pairs[0], params.amountIn);
    }

    return uniswapV2ExactInputInternal(params, path, pairs, amounts);
  }

  function uniswapV2ExactInputPermit(
    ExactInputParams calldata params,
    PermitParams calldata permit
  ) external returns (uint256 amountOut) {
    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    uint256 pathLengthMinusOne = params.path.length - 1;
    address[] memory path = params.path;

    if (params.path[pathLengthMinusOne] == address(0)) {
      // To ETH
      path[pathLengthMinusOne] = address(s.weth);
    }

    (address[] memory pairs, uint256[] memory amounts) = LibUniV2Router.getPairsAndAmountsFromPath(
      s.uniswapV2Factory,
      params.amountIn,
      path
    );

    // Permit tokens / set allowance
    s.permit2.permit(
      msg.sender,
      IAllowanceTransfer.PermitSingle({
        details: IAllowanceTransfer.PermitDetails({
          token: path[0],
          amount: (uint160)(params.amountIn),
          expiration: (uint48)(params.deadline),
          nonce: (uint48)(permit.nonce)
        }),
        spender: address(this),
        sigDeadline: (uint256)(params.deadline)
      }),
      permit.signature
    );

    // Transfer tokens from msg.sender to the first pool
    s.permit2.transferFrom(msg.sender, pairs[0], (uint160)(params.amountIn), params.path[0]);

    return uniswapV2ExactInputInternal(params, path, pairs, amounts);
  }
}
