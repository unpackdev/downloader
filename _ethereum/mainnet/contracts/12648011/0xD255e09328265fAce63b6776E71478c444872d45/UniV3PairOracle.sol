// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-version
pragma solidity 0.7.6;

import "./IUniswapV3Pool.sol";
import "./OracleLibrary.sol";

import "./TickMath.sol";
import "./OwnableNoContext.sol";

interface IOracleInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

contract UniV3PairOracle is OwnableNoContext, IOracleInterface {
    using TickMath for int24;

    IUniswapV3Pool public immutable pool;
    uint256 public constant CONSTANT_DECIMAL = 18;
    uint32 public observationSeconds;
    uint128 public baseAmount;

    constructor(IUniswapV3Pool _pool) {
        pool = _pool;
        observationSeconds = 5 minutes;
        baseAmount = 100;
    }

    function setObservationSeconds(uint32 _newObservationSeconds)
        external
        onlyOwner
    {
        observationSeconds = _newObservationSeconds;
    }

    function setBaseAmount(uint128 _newBaseAmount) external onlyOwner {
        baseAmount = _newBaseAmount;
    }

    function latestAnswer() external view override returns (int256) {
        int24 avgTick =
            OracleLibrary.consult(address(pool), observationSeconds);
        uint256 quoteAmount =
            OracleLibrary.getQuoteAtTick(
                avgTick,
                baseAmount *
                    uint128(10**IOracleInterface(pool.token0()).decimals()),
                pool.token0(),
                pool.token1()
            );
        quoteAmount = quoteAmount / baseAmount;
        return int256(quoteAmount);
    }

    function decimals() external pure override returns (uint256) {
        return CONSTANT_DECIMAL;
    }
}
