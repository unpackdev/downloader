// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./FixedPoint.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./UniswapV2OracleLibrary.sol";


library EmaOracle {
    using FixedPoint for *;
    using SafeMath for uint;

    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
        uint emaPrice0;
        uint emaPrice1;
    }

    struct Observations {
        address factory;
        mapping(uint => mapping(address => Observation)) ppos;
    }

    function initialize(Observations storage os, address factory, uint period, address tokenA, address tokenB) internal {
        os.factory = factory;
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        Observation storage o = os.ppos[period][pair];
        o.timestamp = blockTimestampLast;
        o.price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        o.price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        o.emaPrice0 = FixedPoint.fraction(reserve1, reserve0)._x;
        o.emaPrice1 = FixedPoint.fraction(reserve0, reserve1)._x;
    }

    function calcEmaPrice(uint period, uint timestampStart, uint priceCumulativeStart, uint emaPriceStart, uint timestampEnd, uint priceCumulativeEnd) internal pure returns (uint) {
        uint timeElapsed = timestampEnd.sub(timestampStart);
        if(timeElapsed == 0)
            return emaPriceStart;
        uint priceAverage = priceCumulativeEnd.sub(priceCumulativeStart).div(timeElapsed);
        if(timeElapsed >= period)
            return priceAverage;
        else
            return period.sub(timeElapsed).mul(emaPriceStart).add(timeElapsed.mul(priceAverage)) / period;
    }

    function update(Observations storage os, uint period, address tokenA, address tokenB) internal {
        address pair = UniswapV2Library.pairFor(os.factory, tokenA, tokenB);
        Observation storage o = os.ppos[period][pair];
        uint timeElapsed = block.timestamp.sub(o.timestamp);
        if (timeElapsed > period) {
            (uint price0Cumulative, uint price1Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            o.emaPrice0    = calcEmaPrice(period, o.timestamp, o.price0Cumulative, o.emaPrice0, block.timestamp, price0Cumulative);
            o.emaPrice1    = calcEmaPrice(period, o.timestamp, o.price1Cumulative, o.emaPrice1, block.timestamp, price1Cumulative);
            o.timestamp = block.timestamp;
            o.price0Cumulative = price0Cumulative;
            o.price1Cumulative = price1Cumulative;
        }
    }

    function consultEma(Observations storage os, uint period, address tokenIn, uint amountIn, address tokenOut) internal view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(os.factory, tokenIn, tokenOut);
        Observation storage o = os.ppos[period][pair];
        (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        if (token0 == tokenIn)
            amountOut = FixedPoint.uq112x112(uint224(o.emaPrice0)).mul(amountIn).decode144();
        else
            amountOut = FixedPoint.uq112x112(uint224(o.emaPrice1)).mul(amountIn).decode144();
    }

    function consultNow(Observations storage os, address tokenIn, uint amountIn, address tokenOut) internal view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(os.factory, tokenIn, tokenOut);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        if (token0 == tokenIn)
            amountOut = FixedPoint.fraction(reserve1, reserve0).mul(amountIn).decode144();
        else
            amountOut = FixedPoint.fraction(reserve0, reserve1).mul(amountIn).decode144();
    }

    function consultHi(Observations storage os, uint period, address tokenIn, uint amountIn, address tokenOut) internal view returns (uint amountOut) {
        uint amountOutEma = consultEma(os, period, tokenIn, amountIn, tokenOut);
        uint amountOutNow = consultNow(os, tokenIn, amountIn, tokenOut);
        amountOut = Math.max(amountOutEma, amountOutNow);
    }

    function consultLo(Observations storage os, uint period, address tokenIn, uint amountIn, address tokenOut) internal view returns (uint amountOut) {
        uint amountOutEma = consultEma(os, period, tokenIn, amountIn, tokenOut);
        uint amountOutNow = consultNow(os, tokenIn, amountIn, tokenOut);
        amountOut = Math.min(amountOutEma, amountOutNow);
    }
}
