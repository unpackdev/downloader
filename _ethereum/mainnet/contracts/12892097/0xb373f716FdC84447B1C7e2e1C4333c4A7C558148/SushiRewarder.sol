// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";

interface IUniswapV2Pair {
    function sync() external;
}

contract SushiRewarder {
  using SafeERC20 for IERC20;

  IERC20 public token;
  IUniswapV2Pair public pair;

  constructor(address _token, address _pair) {
    token = IERC20(_token);
    pair = IUniswapV2Pair(_pair);
  }

  function syncTokens(uint amount) external {
    token.transferFrom(msg.sender, address(pair), amount);
    pair.sync();
  }
}
