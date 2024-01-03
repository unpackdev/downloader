// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

interface ITREEOracle {
  function update() external returns (bool success);

  function consult(address token, uint256 amountIn)
    external
    view
    returns (uint256 amountOut);

  function updated() external view returns (bool);

  function updateAndConsult(address token, uint256 amountIn)
    external
    returns (uint256 amountOut);

  function blockTimestampLast() external view returns (uint32);

  function pair() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);
}
