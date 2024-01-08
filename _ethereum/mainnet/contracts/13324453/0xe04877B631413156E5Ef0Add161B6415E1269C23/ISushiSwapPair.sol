// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface ISushiSwapPair {
  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function token0() external view returns (address);

  function token1() external view returns (address);
}
