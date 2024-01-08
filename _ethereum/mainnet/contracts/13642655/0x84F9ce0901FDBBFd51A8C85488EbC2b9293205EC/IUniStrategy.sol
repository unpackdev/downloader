// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IUniStrategy {
    struct PoolStrategy {
        int24 baseThreshold;
        int24 rangeThreshold;
        int24 maxTwapDeviation;
        int24 readjustThreshold;
        uint32 twapDuration;
    }

    event StrategyUpdated(PoolStrategy oldStrategy, PoolStrategy newStrategy);
    event MaxTwapDeviationUpdated(int24 oldDeviation, int24 newDeviation);
    event BaseMultiplierUpdated(int24 oldMultiplier, int24 newMultiplier);
    event RangeMultiplierUpdated(int24 oldMultiplier, int24 newMultiplier);
    event PriceThresholdUpdated(uint24 oldThreshold, uint24 newThreshold);
    event SwapPercentageUpdated(uint8 oldPercentage, uint8 newPercentage);
    event TwapDurationUpdated(uint32 oldDuration, uint32 newDuration);

    function getTicks(address _pool)
        external
        returns (
            int24 baseLower,
            int24 baseUpper,
            int24 bidLower,
            int24 bidUpper,
            int24 askLower,
            int24 askUpper
        );

    function getReadjustThreshold(address _pool)
        external
        view
        returns (int24 readjustThreshold);
}
