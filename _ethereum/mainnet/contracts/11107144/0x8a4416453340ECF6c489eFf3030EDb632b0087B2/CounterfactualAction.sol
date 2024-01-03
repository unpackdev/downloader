// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./PrizePool.sol";
import "./IERC20.sol";

contract CounterfactualAction {
  function depositTo(address payable user, PrizePool prizePool, address output, address referrer) external {
    IERC20 token = prizePool.token();
    uint256 amount = token.balanceOf(address(this));
    token.approve(address(prizePool), amount);
    prizePool.depositTo(user, amount, output, referrer);
    selfdestruct(user);
  }

  function cancel(address payable user, PrizePool prizePool) external {
    IERC20 token = prizePool.token();
    token.transfer(user, token.balanceOf(address(this)));
    selfdestruct(user);
  }
}
