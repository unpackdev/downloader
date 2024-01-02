// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IKeeperRewardDistributorStorage {
    enum DecreasingReason {
        NonExistentIdForLiquidation,
        NonExistentIdForSLOrTP,
        IncorrectConditionForLiquidation,
        IncorrectConditionForSL,
        ClosePostionInTheSameBlock
    }

    enum KeeperActionType {
        OpenByOrder,
        StopLoss,
        TakeProfit,
        Liquidation,
        BucketDelisted
    }

    enum KeeperCallingMethod {
        ClosePositionByCondition,
        OpenPositionByOrder,
        CloseBatchPositions
    }

    /**
     * @dev Structure used in the calculation of keeper rewards in the ARBITRUM payment model
     * @param maxRoutesLength The maximum length of routes for which will be paid keeper rewards, depending on KeeperCallingMethod
     * @param baseLength The static length of the data entering the protocol function, depending on KeeperCallingMethod
     */
    struct DataLengthRestrictions {
        uint256 maxRoutesLength;
        uint256 baseLength;
    }

    /**
     * @dev Structure used in the calculation of maximum gas per position
     * @param baseMaxGas1 Base gas amount that used to calculate max gas amount
     * @param baseMaxGas2 Base gas amount that used to calculate max gas amount when number of keeper actions > inflectionPoint
     * @param multiplier2 The multiplier which is multiplied by the number of keeper actions when number of keeper actions > inflectionPoint
     * @param inflectionPoint Number of actions after which the multiplier2 takes effect
     */
    struct KeeperActionRewardConfig {
        uint256 baseMaxGas1;
        uint256 baseMaxGas2;
        uint256 multiplier1;
        uint256 multiplier2;
        uint256 inflectionPoint;
    }

    struct KeeperBalance {
        uint256 pmxBalance;
        uint256 nativeBalance;
    }
    enum PaymentModel {
        DEFAULT,
        ARBITRUM
    }

    function priceOracle() external view returns (address);

    function registry() external view returns (address);

    function pmx() external view returns (address);

    function treasury() external view returns (address payable);

    function pmxPartInReward() external view returns (uint256);

    function nativePartInReward() external view returns (uint256);

    function positionSizeCoefficientA() external view returns (uint256);

    function positionSizeCoefficientB() external view returns (int256);

    function additionalGas() external view returns (uint256);

    function defaultMaxGasPrice() external view returns (uint256);

    function oracleGasPriceTolerance() external view returns (uint256);

    function paymentModel() external view returns (PaymentModel);

    function keeperBalance(address) external view returns (uint256, uint256);

    function maxGasPerPosition(KeeperActionType) external view returns (uint256, uint256, uint256, uint256, uint256);

    function dataLengthRestrictions(KeeperCallingMethod) external view returns (uint256, uint256);

    function decreasingGasByReason(DecreasingReason) external view returns (uint256);

    function totalBalance() external view returns (uint256, uint256);
}

interface IKeeperRewardDistributorStorageV2 is IKeeperRewardDistributorStorage {
    function minPositionSizeMultiplier() external view returns (int256);
}
