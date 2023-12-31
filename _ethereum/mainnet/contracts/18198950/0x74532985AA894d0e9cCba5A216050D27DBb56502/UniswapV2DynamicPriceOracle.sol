// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router01.sol";

import "./IPriceOracle.sol";

contract UniswapV2DynamicPriceOracle is IPriceOracle {
    IUniswapV2Router01 public uniRouter;

    constructor(IUniswapV2Router01 _uniRouter) {
        uniRouter = _uniRouter;
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(
            amountA > 0,
            "UniswapV2DynamicPriceOracle: INSUFFICIENT_AMOUNT"
        );
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2DynamicPriceOracle: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(
            tokenA != tokenB,
            "UniswapV2DynamicPriceOracle: IDENTICAL_ADDRESSES"
        );
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(
            token0 != address(0),
            "UniswapV2DynamicPriceOracle: ZERO_ADDRESS"
        );
    }

    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view override returns (uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(uniRouter.factory());
        address input = (tokenIn == address(0)) ? uniRouter.WETH() : tokenIn;
        address output = (tokenOut == address(0)) ? uniRouter.WETH() : tokenOut;
        (address token0, ) = sortTokens(input, output);
        IUniswapV2Pair pair = IUniswapV2Pair(
            token0 == input
                ? factory.getPair(input, output)
                : factory.getPair(output, input)
        );
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = token0 == input
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        return quote(amountIn, reserveInput, reserveOutput);
    }
}
