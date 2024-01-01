// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IUniswapV3Pool.sol";
import "./OracleLibrary.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";

import "./IERC20Metadata.sol";
import "./Registry.sol";

import "./IValioCustomAggregator.sol";
import "./IAggregatorV3Interface.sol";

contract UniswapV3TWAPAggregator is IValioCustomAggregator {
    Registry public immutable VALIO_REGISTRY;
    // Number of seconds in the past from which to calculate the time-weighted means
    uint32 public immutable SECONDS_AGO;
    // Configure on a per chain basis, based on number of blocks per minute
    uint public immutable CARDINALITY_PER_MINUTE;

    constructor(
        address _VALIO_REGISTRY,
        uint32 _SECONDS_AGO,
        uint _CARDINALITY_PER_MINUTE
    ) {
        VALIO_REGISTRY = Registry(_VALIO_REGISTRY);
        SECONDS_AGO = _SECONDS_AGO;
        CARDINALITY_PER_MINUTE = _CARDINALITY_PER_MINUTE;
    }

    /// @notice Helper to prepare cardinatily
    function prepareCardinality(IUniswapV3Pool pool) external {
        // We add 1 just to be on the safe side
        uint16 cardinality = uint16(
            (SECONDS_AGO * CARDINALITY_PER_MINUTE) / 60
        ) + 1;
        IUniswapV3Pool(pool).increaseObservationCardinalityNext(cardinality);
    }

    function cardinalityPrepared(
        IUniswapV3Pool pool
    ) external view returns (bool) {
        uint requiredCardinality = _requiredCardinality();
        (, , , , uint16 observationCardinality, , ) = pool.slot0();
        return observationCardinality >= requiredCardinality;
    }

    function latestRoundData(
        address mainToken
    ) external view override returns (int256 answer, uint256 updatedAt) {
        return _latestRoundData(mainToken);
    }

    function getHarmonicMeanLiquidity(
        address mainToken
    ) external view returns (uint256 harmonicMeanLiquidity) {
        RegistryStorage.V3PoolConfig memory v3PoolConfig = VALIO_REGISTRY
            .v3PoolConfig(mainToken);

        (, harmonicMeanLiquidity) = OracleLibrary.consult(
            address(v3PoolConfig.pool),
            SECONDS_AGO
        );
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return 'UniswapV3TWAPAggregator';
    }

    function _requiredCardinality() internal view returns (uint16) {
        return uint16((SECONDS_AGO * CARDINALITY_PER_MINUTE) / 60) + 1;
    }

    function _assertCardinality(IUniswapV3Pool pool) internal view {
        (, , , , uint16 observationCardinality, , ) = pool.slot0();
        uint16 requiredCardinality = _requiredCardinality();
        require(
            observationCardinality >= requiredCardinality,
            'Cardinality not prepared'
        );
    }

    /// @notice Get the latest price from the twap
    /// @return answer The price 10**8
    /// @return updatedAt Timestamp of when the pair token was last updated.
    function _latestRoundData(
        address mainToken
    ) internal view returns (int256 answer, uint256 updatedAt) {
        RegistryStorage.V3PoolConfig memory v3PoolConfig = VALIO_REGISTRY
            .v3PoolConfig(mainToken);
        _assertCardinality(v3PoolConfig.pool);
        address pairToken = v3PoolConfig.pairToken;
        IAggregatorV3Interface pairTokenUsdAggregator = VALIO_REGISTRY
            .chainlinkV3USDAggregators(pairToken);

        uint mainTokenUnit = 10 ** IERC20Metadata(mainToken).decimals();

        uint pairTokenUnit = 10 ** IERC20Metadata(pairToken).decimals();

        (int24 tick, uint128 harmonicMeanLiquidity) = OracleLibrary.consult(
            address(v3PoolConfig.pool),
            SECONDS_AGO
        );

        require(harmonicMeanLiquidity > 0, 'NLQ');

        uint256 quoteAmount = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(mainTokenUnit),
            mainToken,
            pairToken
        );

        int256 pairUsdPrice;
        (, pairUsdPrice, , updatedAt, ) = pairTokenUsdAggregator
            .latestRoundData();

        answer = (pairUsdPrice * int256(quoteAmount)) / int256(pairTokenUnit);

        return (answer, updatedAt);
    }
}
