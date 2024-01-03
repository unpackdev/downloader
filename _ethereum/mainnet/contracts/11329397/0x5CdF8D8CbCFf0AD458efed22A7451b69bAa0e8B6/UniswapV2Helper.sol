// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IUniswapV2Helper.sol";
import "./UniswapV2Library.sol";

contract UniswapV2Helper is IUniswapV2Helper {
    address private immutable uniswapV2Factory;
    address private immutable uniswapV2Router02;
    address private immutable uniswapV2Oracle;

    constructor(
        address _uniswapV2Factory,
        address _uniswapV2Router02,
        address _uniswapV2Oracle
    ) public {
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;
        uniswapV2Oracle = _uniswapV2Oracle;
    }

    function sortTokens(address tokenA, address tokenB)
        external
        pure
        override
        returns (address token0, address token1)
    {
        return UniswapV2Library.sortTokens(tokenA, tokenB);
    }

    function pairFor(address tokenA, address tokenB) external view override returns (address pair) {
        return UniswapV2Library.pairFor(uniswapV2Factory, tokenA, tokenB);
    }

    function getFactoryAddress() external view override returns (address factory) {
        return uniswapV2Factory;
    }

    function getRouterAddress() external view override returns (address router) {
        return uniswapV2Router02;
    }

    function getUniswapV2OracleAddress() external view override returns (address oracle) {
        return uniswapV2Oracle;
    }
}
