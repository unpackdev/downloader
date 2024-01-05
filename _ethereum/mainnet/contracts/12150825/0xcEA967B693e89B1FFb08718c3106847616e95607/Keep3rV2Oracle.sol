// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IKeep3rV1 {
    function keepers(address keeper) external returns (bool);

    function KPRH() external view returns (IKeep3rV1Helper);

    function receipt(
        address credit,
        address keeper,
        uint256 amount
    ) external;
}

interface IKeep3rV1Helper {
    function getQuoteLimit(uint256 gasUsed) external view returns (uint256);
}

// sliding oracle that uses observations collected to provide moving price averages in the past
contract Keep3rV2Oracle {
    constructor(address _pair) {
        _factory = msg.sender;
        pair = _pair;
        (, , uint32 timestamp) = IUniswapV2Pair(_pair).getReserves();
        uint112 _price0CumulativeLast = uint112((IUniswapV2Pair(_pair).price0CumulativeLast() * e10) / Q112);
        uint112 _price1CumulativeLast = uint112((IUniswapV2Pair(_pair).price1CumulativeLast() * e10) / Q112);
        observations[length++] = Observation(timestamp, _price0CumulativeLast, _price1CumulativeLast);
    }

    struct Observation {
        uint32 timestamp;
        uint112 price0Cumulative;
        uint112 price1Cumulative;
    }

    modifier factory() {
        require(msg.sender == _factory, "!F");
        _;
    }

    Observation[65535] public observations;
    uint16 public length;

    address immutable _factory;
    address public immutable pair;
    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint256 constant periodSize = 1800;
    uint256 Q112 = 2**112;
    uint256 e10 = 10**18;

    // Pre-cache slots for cheaper oracle writes
    function cache(uint256 size) external {
        uint256 _length = length + size;
        for (uint256 i = length; i < _length; i++) observations[i].timestamp = 1;
    }

    // update the current feed for free
    function update() external factory returns (bool) {
        return _update();
    }

    function updateable() external view returns (bool) {
        Observation memory _point = observations[length - 1];
        (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();
        uint256 timeElapsed = timestamp - _point.timestamp;
        return timeElapsed > periodSize;
    }

    function _update() internal returns (bool) {
        Observation memory _point = observations[length - 1];
        (, , uint32 timestamp) = IUniswapV2Pair(pair).getReserves();
        uint32 timeElapsed = timestamp - _point.timestamp;
        if (timeElapsed > periodSize) {
            uint112 _price0CumulativeLast = uint112((IUniswapV2Pair(pair).price0CumulativeLast() * e10) / Q112);
            uint112 _price1CumulativeLast = uint112((IUniswapV2Pair(pair).price1CumulativeLast() * e10) / Q112);
            observations[length++] = Observation(timestamp, _price0CumulativeLast, _price1CumulativeLast);
            return true;
        }
        return false;
    }

    function _computeAmountOut(
        uint256 start,
        uint256 end,
        uint256 elapsed,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        amountOut = (amountIn * (end - start)) / e10 / elapsed;
    }

    function current(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo) {
        (address token0, ) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);

        Observation memory _observation = observations[length - 1];
        uint256 price0Cumulative = (IUniswapV2Pair(pair).price0CumulativeLast() * e10) / Q112;
        uint256 price1Cumulative = (IUniswapV2Pair(pair).price1CumulativeLast() * e10) / Q112;
        (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();

        // Handle edge cases where we have no updates, will revert on first reading set
        if (timestamp == _observation.timestamp) {
            _observation = observations[length - 2];
        }

        uint256 timeElapsed = timestamp - _observation.timestamp;
        timeElapsed = timeElapsed == 0 ? 1 : timeElapsed;
        if (token0 == tokenIn) {
            amountOut = _computeAmountOut(_observation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            amountOut = _computeAmountOut(_observation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
        lastUpdatedAgo = timeElapsed;
    }

    function quote(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 points
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo) {
        (address token0, ) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);

        uint256 priceAverageCumulative = 0;
        uint256 _length = length - 1;
        uint256 i = _length - points;
        Observation memory currentObservation;
        Observation memory nextObservation;

        uint256 nextIndex = 0;
        if (token0 == tokenIn) {
            for (; i < _length; i++) {
                nextIndex = i + 1;
                currentObservation = observations[i];
                nextObservation = observations[nextIndex];
                priceAverageCumulative += _computeAmountOut(
                    currentObservation.price0Cumulative,
                    nextObservation.price0Cumulative,
                    nextObservation.timestamp - currentObservation.timestamp,
                    amountIn
                );
            }
        } else {
            for (; i < _length; i++) {
                nextIndex = i + 1;
                currentObservation = observations[i];
                nextObservation = observations[nextIndex];
                priceAverageCumulative += _computeAmountOut(
                    currentObservation.price1Cumulative,
                    nextObservation.price1Cumulative,
                    nextObservation.timestamp - currentObservation.timestamp,
                    amountIn
                );
            }
        }
        amountOut = priceAverageCumulative / points;

        (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();
        lastUpdatedAgo = timestamp - nextObservation.timestamp;
    }

    function sample(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 points,
        uint256 window
    ) external view returns (uint256[] memory prices, uint256 lastUpdatedAgo) {
        (address token0, ) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        prices = new uint256[](points);

        if (token0 == tokenIn) {
            {
                uint256 _length = length - 1;
                uint256 i = _length - (points * window);
                uint256 _index = 0;
                Observation memory nextObservation;
                for (; i < _length; i += window) {
                    Observation memory currentObservation;
                    currentObservation = observations[i];
                    nextObservation = observations[i + window];
                    prices[_index] = _computeAmountOut(
                        currentObservation.price0Cumulative,
                        nextObservation.price0Cumulative,
                        nextObservation.timestamp - currentObservation.timestamp,
                        amountIn
                    );
                    _index = _index + 1;
                }

                (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();
                lastUpdatedAgo = timestamp - nextObservation.timestamp;
            }
        } else {
            {
                uint256 _length = length - 1;
                uint256 i = _length - (points * window);
                uint256 _index = 0;
                Observation memory nextObservation;
                for (; i < _length; i += window) {
                    Observation memory currentObservation;
                    currentObservation = observations[i];
                    nextObservation = observations[i + window];
                    prices[_index] = _computeAmountOut(
                        currentObservation.price1Cumulative,
                        nextObservation.price1Cumulative,
                        nextObservation.timestamp - currentObservation.timestamp,
                        amountIn
                    );
                    _index = _index + 1;
                }

                (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();
                lastUpdatedAgo = timestamp - nextObservation.timestamp;
            }
        }
    }
}
