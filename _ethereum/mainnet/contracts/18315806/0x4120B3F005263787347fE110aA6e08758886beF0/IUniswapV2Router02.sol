// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

interface IUniswapV2Router02 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
}
