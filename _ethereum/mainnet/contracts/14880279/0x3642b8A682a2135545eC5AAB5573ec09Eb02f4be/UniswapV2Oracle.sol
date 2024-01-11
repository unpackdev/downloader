// SPDX-License-Identifier: MIT
// https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "./IUniswapV2.sol";
import "./FixedPoint.sol";
import "./UniswapV2.sol";

contract UniswapV2Oracle {
    using FixedPoint for *;

    uint256 public period;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;

    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    constructor(
        address factory,
        address tokenA,
        address tokenB,
        uint256 _period
    ) {
        period = _period;

        pair = IUniswapV2Pair(
            IUniswapV2Factory(factory).getPair(tokenA, tokenB)
        );

        token0 = pair.token0();
        token1 = pair.token1();

        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast();
        
        (uint112 reserve0,uint112 reserve1,) = pair.getReserves();
        
        price0Average = FixedPoint.fraction(reserve1, reserve0);
        price1Average = FixedPoint.fraction(reserve0, reserve1);

        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 > 0 && reserve1 > 0, "empty-pair");
    }

    function update() public virtual {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        unchecked { 
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

            // ensure that at least one full period has passed since the last update
            require(timeElapsed >= period, "UNIV2ORACLE: PERIOD_NOT_ELAPSED");

            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            price0Average = FixedPoint.uq112x112(
                uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
            );
            price1Average = FixedPoint.uq112x112(
                uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
            );
        }

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn)
        public
        view
        returns (uint256)
    {
        if (token == token0) {
            return price0Average.mul(amountIn).decode144();
        } else if (token == token1) {
            return price1Average.mul(amountIn).decode144();
        }

        revert("UNIV2ORACLE: INVALID_TOKEN");
    }
}