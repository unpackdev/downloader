// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ITroveManager.sol";
import "./ICollateralManager.sol";
import "./IActivePool.sol";
import "./ICollSurplusPool.sol";
import "./IDefaultPool.sol";
import "./IUSDEToken.sol";
import "./ISortedTroves.sol";

library DataTypes {
    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    enum CollStatus {
        nonSupport,
        active,
        pause
    }

    struct CollateralParams {
        uint256 ratio;
        address eToken;
        address oracle;
        CollStatus status;
        uint256 index;
    }

    // Store the necessary data for a trove
    struct Trove {
        mapping(address => uint256) stakes;
        Status status;
        uint128 arrayIndex;
    }

    struct TroveData {
        //borrow index. Expressed in ray
        uint128 borrowIndex;
        //the current borrow rate. Expressed in ray
        uint128 currentBorrowRate;
        uint40 lastUpdateTimestamp;
        //troveManager addresses
        address troveManagerAddress;
        //troveDebt addresses
        address troveDebtAddress;
        //address of the interest rate strategy
        address interestRateAddress;
        //address of the USDE token
        address usdeTokenAddress;
        uint256 factor;
    }

    // Object containing the ETH/wrapperETH and USDE snapshots for a given active trove
    struct RewardSnapshot {
        mapping(address => uint256) USDEDebt;
        mapping(address => uint256) collShares;
    }

    struct ContractsCache {
        ITroveManager troveManager;
        ICollateralManager collateralManager;
        IActivePool activePool;
        IDefaultPool defaultPool;
        IUSDEToken usdeToken;
        ISortedTroves sortedTroves;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
    }

    // --- Variable container structs for liquidations ---

    struct LiquidationValues {
        uint256 entireTroveDebt;
        uint256[] entireTroveColls;
        uint256[] collGasCompensations;
        uint256 USDEGasCompensation;
        uint256 debtToOffset;
        uint256[] collToSendToSPs;
        uint256 debtToRedistribute;
        uint256[] collToRedistributes;
        uint256[] collSurpluses;
    }

    struct LiquidationTotals {
        uint256[] totalCollInSequences;
        uint256 totalDebtInSequence;
        uint256[] totalCollGasCompensations;
        uint256 totalUSDEGasCompensation;
        uint256 totalDebtToOffset;
        uint256[] totalCollToSendToSPs;
        uint256 totalDebtToRedistribute;
        uint256[] totalCollToRedistributes;
        uint256[] totalCollSurpluses;
    }

    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint256 remainingUSDE;
        uint256 totalUSDEToRedeem;
        uint256[] totalCollDrawns;
        uint256 collFee;
        uint256[] collFees;
        uint256[] collToSendToRedeemers;
        uint256 decayedBaseRate;
        uint256 price;
        uint256 totalUSDESupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint256 USDELot;
        address[] collaterals;
        uint256[] collLots;
        uint256[] collRemaind;
        bool cancelledPartial;
    }
}
