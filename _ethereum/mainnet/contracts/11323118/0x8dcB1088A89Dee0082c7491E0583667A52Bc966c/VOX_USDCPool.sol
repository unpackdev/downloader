// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./UniswapPool.sol";

contract VOX_USDCPool is UniswapPool {
  using Address for address;

  string constant _symbol = 'puVOX_USDC';
  string constant _name = 'UniswapPoolVOX_USDC';
  address constant VOX_USDC = 0xe37D2Af2d33049935038826046bC03a62A3A1426;

  constructor (address fees) public UniswapPool(_name, _symbol, VOX_USDC, true, fees) { }

}
