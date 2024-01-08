// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Airdrop {
  using SafeERC20 for IERC20;

  function airdrop(address token, address[] memory destination, uint256[] memory amount)
    public
  {
    require(destination.length == amount.length, "Wait, what?");
    for (uint i = 0; i < destination.length; i++) {
      IERC20(token).safeTransferFrom(msg.sender, destination[i], amount[i]);
    }
  }
}
