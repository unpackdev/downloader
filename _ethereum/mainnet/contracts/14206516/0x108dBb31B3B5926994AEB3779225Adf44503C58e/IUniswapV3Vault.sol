//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.16;

interface IUniswapV3Vault {

  function deposit(
    uint256 _amount0,
    uint256 _amount1,
    bool _zapFunds,
    bool _sweep,
    uint256 _sqrtRatioX96,
    uint256 _tolerance
  ) external returns (uint256, uint256);

  function deposit(
    uint256 _amount0,
    uint256 _amount1,
    bool _zapFunds,
    uint256 _sqrtRatioX96,
    uint256 _tolerance,
    uint256 _zapAmount0OutMin,
    uint256 _zapAmount1OutMin,
    uint160 _zapSqrtPriceLimitX96
  ) external returns (uint256, uint256);

  function withdraw(
    uint256 _numberOfShares,
    bool _token0,
    bool _token1,
    uint256 _sqrtRatioX96,
    uint256 _tolerance
  ) external returns (uint256, uint256);

  function token0() external view returns (address);
  function token1() external view returns (address);
  function getStorage() external view returns (IUniswapV3VaultStorage);
}

interface IUniswapV3VaultStorage {
  function posId() external view returns(uint256);
}