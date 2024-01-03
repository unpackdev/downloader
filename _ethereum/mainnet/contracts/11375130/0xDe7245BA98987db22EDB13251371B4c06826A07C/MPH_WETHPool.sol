// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./UniswapPool.sol";

contract MPH_WETHPool is UniswapPool {
  using Address for address;

  string constant _symbol = 'puMPH_WETH';
  string constant _name = 'UniswapPoolMPH_WETH';
  address constant MPH_WETH = 0x4D96369002fc5b9687ee924d458A7E5bAa5df34E;

  constructor (address fees) public UniswapPool(_name, _symbol, MPH_WETH, true, fees) { }

}
