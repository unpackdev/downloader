// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./TokenController.sol";

contract TokenControllerEth is TokenController {
  using SafeERC20 for IERC20;

  IERC20 public immutable prq;

  constructor(IERC20 _prq) TokenController() {
    prq = _prq;
  }

  /**
   * @inheritdoc ITokenController
   */
  function releaseTokens(address recipient, uint256 amount) external checkBridge {
    prq.transfer(recipient, amount);
  }

  /**
   * @inheritdoc ITokenController
   */
  function reserveTokens(address sender, uint256 amount) external checkBridge {
    prq.safeTransferFrom(sender, address(this), amount);
  }
}
