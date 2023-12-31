// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

import "./IERC20.sol";
import "./IGovBridge.sol";

contract MockGovBridge {
  event Deposit(address indexed receiver);

  function deposit(
    address token,
    uint256 amount,
    address receiver
  ) external {
    IERC20(token).transferFrom(msg.sender, address(this), amount);
    emit Deposit(receiver);
  }
}
