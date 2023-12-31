// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./LibUniV3Like.sol";
import "./IUniV3Callback.sol";

contract UniV3Callback is IUniV3Callback {
  using SafeERC20 for IERC20;

  /**
   * See https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol
   *
   * NOTE: None of these arguments can be trusted
   */
  function uniswapV3SwapCallback(int256, int256, bytes calldata) external {
    if (LibUniV3Like.state().isActive != 1) {
      revert CallbackInactive();
    }

    LibUniV3Like.CallbackState memory callback = LibUniV3Like.state().callback;

    if (callback.payer == address(this)) {
      IERC20(callback.token).safeTransfer(msg.sender, callback.amount);
    } else {
      IERC20(callback.token).safeTransferFrom(callback.payer, msg.sender, callback.amount);
    }

    LibUniV3Like.state().isActive = 0;
  }
}
