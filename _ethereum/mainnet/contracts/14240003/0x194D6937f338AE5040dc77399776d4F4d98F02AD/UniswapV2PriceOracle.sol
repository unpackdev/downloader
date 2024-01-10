// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";

import "./FullMath.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

contract UniswapV2PriceOracle {
    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    uint256 public constant OBSERVATION_BUFFER_SIZE = 8;
    uint256 public constant MIN_TWAP_TIME = 30 minutes;

    mapping(address => Observation[OBSERVATION_BUFFER_SIZE]) public pairObservations;
    mapping(address => uint256) public numPairObservations;

    // Logic adapted from https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/examples/ExampleSlidingWindowOracle.sol#L69.
    function update(address pair) internal returns (bool) {
        if (
            numPairObservations[pair] > 0 &&
            (block.timestamp - pairObservations[pair][(numPairObservations[pair] - 1) % OBSERVATION_BUFFER_SIZE].timestamp) <= MIN_TWAP_TIME
        ) {
            return false;
        }
        (uint256 px0Cumulative, uint256 px1Cumulative) = cumulativePrices(pair);
        pairObservations[pair][numPairObservations[pair]++ % OBSERVATION_BUFFER_SIZE] = Observation(
            block.timestamp,
            px0Cumulative,
            px1Cumulative
        );
        return true;
    }

    function update(address[] calldata pairs) external returns (uint256) {
        uint256 numberUpdated = 0;
        for (uint256 i = 0; i < pairs.length; ++i) {
            if (update(pairs[i])) {
                ++numberUpdated;
            }
        }
        return numberUpdated;
    }

    // Adapted from https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/libraries/UniswapV2OracleLibrary.sol#L16.
    /// @dev Using this function instead of calling `price0Cumulative` and `price1Cumulative` saves gas.
    function cumulativePrices(
        address pair
    ) internal view returns (uint256 px0Cumulative, uint256 px1Cumulative) {
        px0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        px1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        // If time has elapsed since the last update on the pair, mock the accumulated price values.
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        unchecked {
            uint32 timeElapsed = uint32(block.timestamp % (2**32)) - blockTimestampLast;
            if (timeElapsed != 0) {
                require(
                    reserve0 > 0 && reserve1 > 0,
                    "UniswapV2PriceOracle: Division by zero."
                );
                // Addition overflow is desired.
                px0Cumulative += uint256((uint224(reserve1) << 112) / reserve0) * timeElapsed;
                px1Cumulative += uint256((uint224(reserve0) << 112) / reserve1) * timeElapsed;
            }
        }
    }

    // Adapted from https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/libraries/UniswapV2OracleLibrary.sol#L16.
    function price0Cumulative(address pair) internal view returns (uint256) {
        uint256 px0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        // If time has elapsed since the last update on the pair, mock the accumulated price values.
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        // Subtraction overflow is desired.
        unchecked {
            uint32 timeElapsed = uint32(block.timestamp % (2**32)) - blockTimestampLast;
            if (timeElapsed != 0) {
                require(
                    reserve0 > 0,
                    "UniswapV2PriceOracle: Division by zero."
                );
                // Addition overflow is desired.
                px0Cumulative += uint256((uint224(reserve1) << 112) / reserve0) * timeElapsed;
            }
        }
        return px0Cumulative;
    }

    // Adapted from https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/libraries/UniswapV2OracleLibrary.sol#L16.
    function price1Cumulative(address pair) internal view returns (uint256) {
        uint256 px1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        // If time has elapsed since the last update on the pair, mock the accumulated price values.
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        // Subtraction overflow is desired.
        unchecked {
            uint32 timeElapsed = uint32(block.timestamp % (2**32)) - blockTimestampLast;
            if (timeElapsed != 0) {
                require(
                    reserve1 > 0,
                    "UniswapV2PriceOracle: Division by zero."
                );
                // Addition overflow is desired.
                px1Cumulative += uint256((uint224(reserve0) << 112) / reserve1) * timeElapsed;
            }
        }
        return px1Cumulative;
    }

    // Adapted from https://github.com/AlphaFinanceLab/alpha-homora-v2-contract/blob/f74fc460bd614ad15bbef57c88f6b470e5efd1fd/contracts/oracle/BaseKP3ROracle.sol#L26.
    function price0(address pair) internal view returns (uint256) {
        uint256 length = numPairObservations[pair];
        require(length > 0, "UniswapV2PriceOracle: No observations.");
        Observation storage lastObservation = pairObservations[pair][(length - 1) % OBSERVATION_BUFFER_SIZE];
        if (lastObservation.timestamp > block.timestamp - MIN_TWAP_TIME) {
            require(length > 1, "UniswapV2PriceOracle: Only one observation.");
            lastObservation = pairObservations[pair][(length - 2) % OBSERVATION_BUFFER_SIZE];
        }
        // This shouldn't fail.
        require(
            block.timestamp - lastObservation.timestamp >= MIN_TWAP_TIME,
            "UniswapV2PriceOracle: Bad TWAP time."
        );
        uint256 px0Cumulative = price0Cumulative(pair);
        unchecked {
            // Overflow is desired.
            return (px0Cumulative - lastObservation.price0Cumulative) / (block.timestamp - lastObservation.timestamp);
        }
    }

    // Adapted from https://github.com/AlphaFinanceLab/alpha-homora-v2-contract/blob/f74fc460bd614ad15bbef57c88f6b470e5efd1fd/contracts/oracle/BaseKP3ROracle.sol#L26.
    function price1(address pair) internal view returns (uint256) {
        uint256 length = numPairObservations[pair];
        require(length > 0, "UniswapV2PriceOracle: No observations.");
        Observation storage lastObservation = pairObservations[pair][(length - 1) % OBSERVATION_BUFFER_SIZE];
        if (lastObservation.timestamp > block.timestamp - MIN_TWAP_TIME) {
            require(length > 1, "UniswapV2PriceOracle: Only one observation.");
            lastObservation = pairObservations[pair][(length - 2) % OBSERVATION_BUFFER_SIZE];
        }
        // This shouldn't fail.
        require(
            block.timestamp - lastObservation.timestamp >= MIN_TWAP_TIME,
            "UniswapV2PriceOracle: Bad TWAP time."
        );
        uint256 px1Cumulative = price1Cumulative(pair);
        unchecked {
            // Overflow is desired.
            return (px1Cumulative - lastObservation.price1Cumulative) / (block.timestamp - lastObservation.timestamp);
        }
    }

    /**
     * @notice Returns the price of `token` in terms of `baseToken`, scaled up by the units of `baseToken`.
     */
    function price(
        address token,
        address baseToken,
        address factory
    ) external view returns (uint256) {
        address pair = IUniswapV2Factory(factory).getPair(token, baseToken);
        uint256 baseUnit = 10**uint256(ERC20(token).decimals());
        return FullMath.mulDiv(token < baseToken ? price0(pair) : price1(pair), baseUnit, 2**112);
    }
}
