//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.5;

import "./IERC20.sol";
import "./IBalancer.sol";

contract Balancer is IBalancerPool {
  function swapExactAmountIn(
    address _tokenIn,
    uint256 _tokenAmountIn,
    address _tokenOut,
    uint256 _minAmountOut,
    uint256 _maxPrice
  ) external override returns (uint256, uint256) {
    require(_maxPrice == uint256(-1), "Unsupported maxPrice");

    address me = address(this);
    IERC20 tokenIn = IERC20(_tokenIn);
    IERC20 tokenOut = IERC20(_tokenOut);

    uint256 tokenAmountOut = (10**18 * tokenOut.balanceOf(me) * _tokenAmountIn);
    tokenAmountOut /= (10**18 * tokenIn.balanceOf(me));

    require(tokenAmountOut > _minAmountOut, "Insufficient amount out");

    require(tokenIn.transferFrom(msg.sender, me, _tokenAmountIn), "Transfer in failed");

    require(tokenOut.transfer(msg.sender, tokenAmountOut), "Transfer out failed");

    return (tokenAmountOut, 0);
  }
}
