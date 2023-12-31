// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./ERC20.sol";

library ERC20Lib {
  function _balanceOfThis(IERC20 token) internal view returns (uint) {
    return token.balanceOf(address(this));
  }

  function _approve(IERC20 token, address spender, uint amount) internal returns (bool) {
    return token.approve(spender, amount);
  }
}