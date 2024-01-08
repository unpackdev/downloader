// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";

import "./UniswapV2OracleLibrary.sol";
import "./IOracleSimple.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleSimple is IOracleSimple {
    using FixedPoint for *;

    /* solhint-disable var-name-mixedcase */
    uint256 public immutable PERIOD;
    IUniswapV2Pair public immutable PAIR;

    /* solhint-enable */

    address public immutable token0;
    address public immutable token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;
    bool public isStale;

    constructor(address _pair, uint256 _period) {
        PERIOD = _period;
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        PAIR = pair;
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "OracleSimple: NO_RESERVES"); // ensure that there's liquidity in the pair
    }

    function update() external override returns (bool) {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(PAIR));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if (timeElapsed < PERIOD) return false;

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(
            uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
        );
        price1Average = FixedPoint.uq112x112(
            uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
        );

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
        return true;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, "OracleSimple: INVALID_TOKEN");
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}
