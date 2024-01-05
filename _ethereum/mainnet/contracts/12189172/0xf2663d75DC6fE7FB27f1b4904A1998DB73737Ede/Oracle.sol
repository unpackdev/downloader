//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./ReentrancyGuard.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";

import "./Debouncable.sol";
import "./Timeboundable.sol";
import "./IOracle.sol";

/// Fixed window oracle that recomputes the average price for the entire period once every period
/// @title Oracle
/// @dev note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract Oracle is Debouncable, Timeboundable, IOracle, ReentrancyGuard {
    using FixedPoint for *;

    IUniswapV2Pair public immutable override pair;
    address public immutable override token0;
    address public immutable override token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    /// Creates an Oracle
    /// @param _factory UniswapV2 factory address.
    /// @param _tokenA 1st token address.
    /// @param _tokenB 2nd token address.
    /// @param _period Price average period in seconds.
    /// @param _start Start (block timestamp).
    constructor(
        address _factory,
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _start
    ) public Debouncable(_period) Timeboundable(_start, 0) {
        IUniswapV2Pair _pair =
            IUniswapV2Pair(
                UniswapV2Library.pairFor(_factory, _tokenA, _tokenB)
            );
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(
            reserve0 != 0 && reserve1 != 0,
            "Oracle: No reserves in the uniswap pool"
        ); // ensure that there's liquidity in the pair
    }

    /// Updates oracle price
    /// @dev Works only once in a period, other times reverts
    function update()
        external
        override
        debounce()
        inTimeBounds()
        nonReentrant()
    {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint256 timeElapsed = block.timestamp - lastCalled;
        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(
            uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
        );
        price1Average = FixedPoint.uq112x112(
            uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
        );
        emit Updated(
            price0CumulativeLast,
            price0Cumulative,
            price1CumulativeLast,
            price1Cumulative
        );
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    /// Get the price of token.
    /// @param token The address of one of two tokens (the one to get the price for)
    /// @param amountIn The amount of token to estimate
    /// @return amountOut The amount of other token equivalent
    /// @dev This will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn)
        external
        view
        override
        inTimeBounds()
        returns (uint256 amountOut)
    {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, "Oracle: Invalid token address");
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }

    event Updated(
        uint256 price0CumulativeBefore,
        uint256 price0CumulativeAfter,
        uint256 price1CumulativeBefore,
        uint256 price1CumulativeAfter
    );
}
