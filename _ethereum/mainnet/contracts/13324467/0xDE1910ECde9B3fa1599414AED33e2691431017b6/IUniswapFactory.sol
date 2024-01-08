// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IUniswapFactory {
  /// @param tokenA The contract address of either token0 or token1
  /// @param tokenB The contract address of the other token
  /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
  /// @return pool The pool address
  function getPool(
    address tokenA,
    address tokenB,
    uint24 fee
  ) external view returns (address pool);
}
