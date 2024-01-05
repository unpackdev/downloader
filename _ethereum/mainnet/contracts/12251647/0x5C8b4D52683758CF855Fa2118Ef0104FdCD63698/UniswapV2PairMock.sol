// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

contract UniswapV2PairMock {
  
  address public token0;
  uint256 public price0CumulativeLast;
  address public token1;
  uint256 public price1CumulativeLast;

  constructor(
    address firstToken,
    address secondToken
  ) {
    token0 = firstToken;
    token1 = secondToken;
  }

  function setPrice0(
    uint newPrice
  )
    external
  {
    price0CumulativeLast = newPrice;
  }

  function setPrice1(
    uint newPrice
  )
    external
  {
    price1CumulativeLast = newPrice;
  }

}
