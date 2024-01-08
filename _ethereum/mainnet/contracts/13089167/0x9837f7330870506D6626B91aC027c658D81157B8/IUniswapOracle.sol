
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapOracle
{
    function PERIOD() external returns (uint);
    function factory() external returns (address);
    function update(
      address _tokenIn,
      address _tokenOut
    ) external;
    function consult(
      address _tokenIn,
      uint _amountIn,
      address _tokenOut
    ) external view
      returns (uint _amountOut);
    function updateAndConsult(
      address _tokenIn,
      uint _amountIn,
      address _tokenOut
    ) external
      returns (uint _amountOut);
}