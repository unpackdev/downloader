// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./UniswapPool.sol";

contract PUUL_USDCPool is UniswapPool {
  using Address for address;

  string constant _symbol = 'puPUUL_USDC';
  string constant _name = 'UniswapPoolPUUL_USDC';

  constructor (address PUUL_USDC, address fees) public UniswapPool(_name, _symbol, PUUL_USDC, true, fees) { }

  function earn() onlyHarvester nonReentrant override virtual external {
  }

  function unearn() onlyHarvester nonReentrant override virtual external {
  }

  function liquidate() onlyHarvester nonReentrant override virtual external {
  }

}
