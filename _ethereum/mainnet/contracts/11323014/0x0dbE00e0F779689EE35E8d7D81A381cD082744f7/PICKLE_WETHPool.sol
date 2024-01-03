// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./UniswapPool.sol";

contract PICKLE_WETHPool is UniswapPool {
  using Address for address;

  string constant _symbol = 'puPICKLE_WETH';
  string constant _name = 'UniswapPoolPICKLE_WETH';
  address constant PICKLE_WETH = 0xdc98556Ce24f007A5eF6dC1CE96322d65832A819;

  constructor (address fees) public UniswapPool(_name, _symbol, PICKLE_WETH, true, fees) { }

}
