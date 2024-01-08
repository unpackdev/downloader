// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface ISushiSwapFactory {
  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);
}
