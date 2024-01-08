// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IUniswapPairOracle {

    function consult(address token, uint amountIn) external view returns (uint amountOut);
}
