// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "./IERC20Ext.sol";


interface IDMMPool {
  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
  function getTradeInfo()
    external view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint112 _vReserve0,
      uint112 _vReserve1,
      uint256 feeInPrecision
  );

  function token0() external view returns (IERC20Ext);

  function token1() external view returns (IERC20Ext);
}
