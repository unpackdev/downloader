// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IUniswapPriceConverter {

  function assetToEth(
    address _tokenIn,
    uint256 _amountIn,
    uint32  _twapPeriod
  ) external view returns (uint256 ethAmountOut);
}