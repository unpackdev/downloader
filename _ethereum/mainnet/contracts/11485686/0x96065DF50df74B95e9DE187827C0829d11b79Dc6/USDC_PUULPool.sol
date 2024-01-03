// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./UniswapStakingPool.sol";

contract USDC_PUULPool is UniswapStakingPool {
  using Address for address;

  string constant _symbol = 'puUSDC_PUUL';
  string constant _name = 'UniswapPoolUSDC_PUUL';
  address constant USDC_PUUL = address(0x69C11aB150587736E63B2825de55cA7486983D07);

  constructor (address fees) public UniswapStakingPool(_name, _symbol, USDC_PUUL, fees) { }
}
