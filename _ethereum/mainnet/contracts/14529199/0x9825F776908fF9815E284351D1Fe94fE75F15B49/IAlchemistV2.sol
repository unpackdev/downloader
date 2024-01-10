pragma solidity ^0.8.11;

interface IAlchemistV2 {
    struct YieldTokenParams {
        uint8 decimals;
        address underlyingToken;
        address adapter;
        uint256 maximumLoss;
        uint256 maximumExpectedValue;
        uint256 creditUnlockRate;
        uint256 activeBalance;
        uint256 harvestableBalance;
        uint256 totalShares;
        uint256 expectedValue;
        uint256 pendingCredit;
        uint256 distributedCredit;
        uint256 lastDistributionBlock;
        uint256 accruedWeight;
        bool enabled;
    }

    struct YieldTokenConfig {
        address adapter;
        uint256 maximumLoss;
        uint256 maximumExpectedValue;
        uint256 creditUnlockRate;
    }

    function harvest(address yieldToken, uint256 minimumAmountOut) external;

    function getYieldTokenParameters(address yieldToken)
        external
        view
        returns (YieldTokenParams memory params);
}
