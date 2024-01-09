// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./ERC20Mock.sol";

contract UniswapV2PairMock is ERC20Mock {
  address public token0;
  address public token1;

  constructor(
    address _token0,
    address _token1,
    uint256 initialSupply
  ) ERC20Mock("Uniswap V2", "UNI-V2", initialSupply) {
    token0 = _token0;
    token1 = _token1;
  }
}
