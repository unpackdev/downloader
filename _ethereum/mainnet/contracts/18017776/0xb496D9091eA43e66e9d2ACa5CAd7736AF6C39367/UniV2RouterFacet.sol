// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniV2Router.sol";
import "./LibUniV2Router.sol";
import "./LibKitty.sol";
import "./Errors.sol";

contract UniV2RouterFacet is IUniV2Router {
  using SafeERC20 for IERC20;
  using Address for address;

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
    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    path[0] = address(s.weth);

    uint256 amountOutMin = (amountOut * (10_000 - slippage)) / 10_000;

    unchecked {
      amounts = s.uniswapV2router02.swapExactETHForTokens{value: msg.value}(
        amountOutMin,
        path,
        address(this),
        deadline
      );
    }

    uint256 pathLengthMinusOne = path.length - 1;

    amounts[pathLengthMinusOne] = LibKitty.calculateAndRegisterFee(
      partner,
      path[pathLengthMinusOne],
      feeBps,
      amountOut,
      amounts[pathLengthMinusOne]
    );

    // Transfer tokens to user
    IERC20(path[pathLengthMinusOne]).safeTransfer(to, amounts[pathLengthMinusOne]);

    return amounts;
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
    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);

    IERC20(path[0]).safeApprove(address(s.uniswapV2router02), amountIn);

    uint256 pathLengthMinusOne = path.length - 1;

    path[pathLengthMinusOne] = address(s.weth);

    uint256 amountOutMin = (amountOut * (10_000 - slippage)) / 10_000;

    unchecked {
      amounts = s.uniswapV2router02.swapExactTokensForETH(
        amountIn,
        amountOutMin,
        path,
        address(this),
        deadline
      );
    }

    amounts[pathLengthMinusOne] = LibKitty.calculateAndRegisterFee(
      partner,
      // NOTE: `path[pathLengthMinusOne]` cannot be used since it's set to WETH
      address(0),
      feeBps,
      amountOut,
      amounts[pathLengthMinusOne]
    );

    // Transfer ETH to user
    (bool sent, ) = to.call{value: amounts[pathLengthMinusOne]}('');

    if (!sent) {
      revert Errors.EthTransferFailed();
    }

    return amounts;
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
    LibUniV2Router.DiamondStorage storage s = LibUniV2Router.diamondStorage();

    IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);

    IERC20(path[0]).safeApprove(address(s.uniswapV2router02), amountIn);

    uint256 amountOutMin = (amountOut * (10_000 - slippage)) / 10_000;

    unchecked {
      amounts = s.uniswapV2router02.swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        path,
        address(this),
        deadline
      );
    }

    uint256 pathLengthMinusOne = path.length - 1;

    amounts[pathLengthMinusOne] = LibKitty.calculateAndRegisterFee(
      partner,
      path[pathLengthMinusOne],
      feeBps,
      amountOut,
      amounts[pathLengthMinusOne]
    );

    // Transfer tokens to user
    IERC20(path[pathLengthMinusOne]).safeTransfer(to, amounts[pathLengthMinusOne]);

    return amounts;
  }
}
