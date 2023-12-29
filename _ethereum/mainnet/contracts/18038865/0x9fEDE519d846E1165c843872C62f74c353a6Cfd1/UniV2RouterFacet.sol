// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniV2Router.sol";
import "./LibUniV2Router.sol";
import "./LibKitty.sol";
import "./Errors.sol";
import "./IUniswapV2Pair.sol";

contract UniV2RouterFacet is IUniV2Router {
  using SafeERC20 for IERC20;
  using Address for address;

  // TODO: Change to external once the legacy functions are removed
  function uniswapV2ExactInputSingle(
    ExactInputSingleParams memory params
  ) public payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert Errors.DeadlineExpired();
    }

    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    bool isFromEth = params.tokenIn == address(0);
    bool isToEth = params.tokenOut == address(0);

    if (isFromEth) {
      params.tokenIn = address(s.weth);
    }

    if (isToEth) {
      params.tokenOut = address(s.weth);
    }

    address pair = LibUniV2Router.pairFor(s.uniswapV2Factory, params.tokenIn, params.tokenOut);

    (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(pair).getReserves();

    if (params.tokenIn > params.tokenOut) {
      (reserveIn, reserveOut) = (reserveOut, reserveIn);
    }

    unchecked {
      amountOut =
        ((params.amountIn * 997) * reserveOut) /
        ((reserveIn * 1000) + (params.amountIn * 997));
    }

    // Enforce minimum amount/max slippage
    if (amountOut < LibUniV2Router.applySlippage(params.amountOut, params.slippage)) {
      revert Errors.InsufficientOutputAmount();
    }

    if (isFromEth) {
      // From ETH
      if (msg.value != params.amountIn) {
        revert Errors.IncorrectEthValue();
      }

      s.weth.deposit{value: msg.value}();

      // Transfer tokens to the pool
      IERC20(params.tokenIn).safeTransfer(pair, params.amountIn);
    } else {
      // Transfer tokens from the sender to the pool
      IERC20(params.tokenIn).safeTransferFrom(msg.sender, pair, params.amountIn);
    }

    bool zeroForOne = params.tokenIn < params.tokenOut ? true : false;

    IUniswapV2Pair(pair).swap(
      zeroForOne ? 0 : amountOut,
      zeroForOne ? amountOut : 0,
      address(this),
      ''
    );

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibKitty.calculateAndRegisterFee(
      params.partner,
      params.tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (amountOut == 0) {
      revert Errors.ZeroAmountOut();
    }

    if (isToEth) {
      // Unwrap WETH
      s.weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert Errors.EthTransferFailed();
      }
    } else {
      IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);
    }
  }

  // TODO: Change to external once the legacy functions are removed
  function uniswapV2ExactInput(
    ExactInputParams memory params
  ) public payable returns (uint256 amountOut) {
    if (block.timestamp > params.deadline) {
      revert Errors.DeadlineExpired();
    }

    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    uint256 pathLengthMinusOne = params.path.length - 1;
    bool isFromEth = params.path[0] == address(0);
    bool isToEth = params.path[pathLengthMinusOne] == address(0);

    if (isFromEth) {
      params.path[0] = address(s.weth);
    }

    if (isToEth) {
      params.path[pathLengthMinusOne] = address(s.weth);
    }

    (address[] memory pairs, uint256[] memory amounts) = LibUniV2Router.getPairsAndAmountsFromPath(
      s.uniswapV2Factory,
      params.amountIn,
      params.path
    );

    // Enforce minimum amount/max slippage
    if (
      amounts[amounts.length - 1] < LibUniV2Router.applySlippage(params.amountOut, params.slippage)
    ) {
      revert Errors.InsufficientOutputAmount();
    }

    if (isFromEth) {
      // From ETH
      if (msg.value != params.amountIn) {
        revert Errors.IncorrectEthValue();
      }

      s.weth.deposit{value: msg.value}();

      // Transfer tokens to the first pool
      IERC20(params.path[0]).safeTransfer(pairs[0], params.amountIn);
    } else {
      // Transfer tokens from the sender to the first pool
      IERC20(params.path[0]).safeTransferFrom(msg.sender, pairs[0], params.amountIn);
    }

    // From https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol
    for (uint index; index < pathLengthMinusOne; ) {
      uint256 indexPlusOne = index + 1;
      bool zeroForOne = params.path[index] < params.path[indexPlusOne] ? true : false;
      address to = index < params.path.length - 2 ? pairs[indexPlusOne] : address(this);

      IUniswapV2Pair(pairs[index]).swap(
        zeroForOne ? 0 : amounts[indexPlusOne],
        zeroForOne ? amounts[indexPlusOne] : 0,
        to,
        ''
      );

      unchecked {
        index++;
      }
    }

    // NOTE: Fee is collected as WETH instead of ETH
    amountOut = LibKitty.calculateAndRegisterFee(
      params.partner,
      params.path[pathLengthMinusOne],
      params.feeBps,
      params.amountOut,
      amounts[pathLengthMinusOne]
    );

    if (amountOut == 0) {
      revert Errors.ZeroAmountOut();
    }

    if (isToEth) {
      // Unwrap WETH
      s.weth.withdraw(amountOut);

      (bool sent, ) = params.recipient.call{value: amountOut}('');

      if (!sent) {
        revert Errors.EthTransferFailed();
      }
    } else {
      IERC20(params.path[pathLengthMinusOne]).safeTransfer(params.recipient, amountOut);
    }
  }

  /**
   * @param amountOut Amount out before slippage
   * @param path [input coin, ..., output coin]
   * @param to Recipient of output coin
   * @param slippage Slippage tolerance in bps
   * @param deadline Deadline in unix timestamp
   */
  function uniswapV2SwapExactETHForTokens(
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 slippage,
    uint256 deadline,
    address partner,
    uint16 feeBps
  ) external payable returns (uint256[] memory amounts) {
    amounts = new uint256[](path.length);
    amounts[0] = msg.value;

    // NOTE: May have been passed in as 0xeee
    path[0] = address(0);

    amounts[path.length - 1] = uniswapV2ExactInput(
      ExactInputParams({
        amountIn: msg.value,
        amountOut: amountOut,
        recipient: to,
        slippage: (uint16)(slippage),
        feeBps: feeBps,
        deadline: (uint48)(deadline),
        partner: partner,
        path: path
      })
    );
  }

  function uniswapV2SwapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOut,
    address[] memory path,
    address payable to,
    uint256 slippage,
    uint256 deadline,
    address partner,
    uint16 feeBps
  ) external returns (uint256[] memory amounts) {
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;

    // NOTE: May have been passed in as 0xeee
    path[path.length - 1] = address(0);

    amounts[path.length - 1] = uniswapV2ExactInput(
      ExactInputParams({
        amountIn: amountIn,
        amountOut: amountOut,
        recipient: to,
        slippage: (uint16)(slippage),
        feeBps: feeBps,
        deadline: (uint48)(deadline),
        partner: partner,
        path: path
      })
    );
  }

  function uniswapV2SwapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 slippage,
    uint256 deadline,
    address partner,
    uint16 feeBps
  ) external returns (uint256[] memory amounts) {
    amounts = new uint256[](path.length);

    amounts[0] = amountIn;

    amounts[path.length - 1] = uniswapV2ExactInput(
      ExactInputParams({
        amountIn: amountIn,
        amountOut: amountOut,
        recipient: to,
        slippage: (uint16)(slippage),
        feeBps: feeBps,
        deadline: (uint48)(deadline),
        partner: partner,
        path: path
      })
    );
  }
}
