// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./UniswapPool.sol";

contract USDC_BONDPool is UniswapPool {
  using Address for address;

  string constant _symbol = 'puUSDC_BOND';
  string constant _name = 'UniswapPoolUSDC_BOND';
  address constant USDC_BOND = 0x6591c4BcD6D7A1eb4E537DA8B78676C1576Ba244;

  constructor (address fees) public UniswapPool(_name, _symbol, USDC_BOND, true, fees) { }

}
