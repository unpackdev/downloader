// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ISweeper.sol";
import "./Errors.sol";

abstract contract SweepBase is ISweeper {
  address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function sweepToken(
    address token,
    address to,
    uint256 amount
  ) external override {
    _onlySweepAdmin();
    if (token == ETH) {
      Address.sendValue(payable(to), amount);
    } else {
      SafeERC20.safeTransfer(IERC20(token), to, amount);
    }
  }

  function _onlySweepAdmin() internal view virtual;
}
