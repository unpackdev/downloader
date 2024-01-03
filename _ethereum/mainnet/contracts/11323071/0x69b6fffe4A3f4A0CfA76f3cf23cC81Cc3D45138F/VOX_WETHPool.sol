// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./UniswapPool.sol";

contract VOX_WETHPool is UniswapPool {
  using Address for address;

  string constant _symbol = 'puVOX_WETH';
  string constant _name = 'UniswapPoolVOX_WETH';
  address constant VOX_WETH = 0x3D3eE86a2127F4D20b1c533E2c1abd8040da1dd9;

  constructor (address fees) public UniswapPool(_name, _symbol, VOX_WETH, true, fees) { }

}
