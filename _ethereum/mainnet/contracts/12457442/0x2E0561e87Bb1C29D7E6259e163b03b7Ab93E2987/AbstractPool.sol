// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20DecimalsExt.sol";
import "./BalancerOwnable.sol";

abstract contract AbstractPool is IERC20DecimalsExt, BalancerOwnable {
  function setSwapFee(uint swapFee) external virtual;
  function setPublicSwap(bool public_) external virtual;
  function isPublicSwap() external virtual view returns (bool);
  function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external virtual;
}