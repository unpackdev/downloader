// SPDX-License-Identifier: GPL-3.0

import "./IStableMaster.sol";

pragma solidity ^0.8.7;

struct PoolParameters {
    uint64[] xFeeMint;
    uint64[] yFeeMint;
    uint64[] xFeeBurn;
    uint64[] yFeeBurn;
    uint64[] xHAFeesDeposit;
    uint64[] yHAFeesDeposit;
    uint64[] xHAFeesWithdraw;
    uint64[] yHAFeesWithdraw;
    uint256[] xSlippageFee;
    uint64[] ySlippageFee;
    uint256[] xSlippage;
    uint64[] ySlippage;
    uint256[] xBonusMalusMint;
    uint64[] yBonusMalusMint;
    uint256[] xBonusMalusBurn;
    uint64[] yBonusMalusBurn;
    uint64[] xKeeperFeesClosing;
    uint64[] yKeeperFeesClosing;
    uint64 haFeeDeposit;
    uint64 haFeeWithdraw;
    uint256 capOnStableMinted;
    uint256 maxInterestsDistributed;
    uint64 feesForSLPs;
    uint64 interestsForSLPs;
    uint64 targetHAHedge;
    uint64 limitHAHedge;
    uint64 maxLeverage;
    uint64 maintenanceMargin;
    uint64 lockTime;
    uint64 keeperFeesLiquidationRatio;
    uint256 keeperFeesLiquidationCap;
    uint256 keeperFeesClosingCap;
}

/// @title OrchestratorOwnable
/// @author Angle Core Team
/// @notice Contract that is used to facilitate the deployment of a given collateral on mainnet
contract OrchestratorOwnable {
    /// @notice Address that is allowed to call the `initCollateral` function
    address public owner;

    /// @notice Initializes the `owner` of the contract
    constructor(address _owner) {
        owner = _owner;
    }

    /// @notice Changes the owner of a contract
    /// @param _newOwner New owner of the contract
    /// @dev With this function the timelock can be given the ownership of the contract
    function setOwner(address _newOwner) external {
        require(msg.sender == owner, "79");
        owner = _newOwner;
    }

    /// @notice Initializes a pool
    /// @param p List of all the parameters with which to initialize the pool
    /// @dev Only the `owner` can call this function

    function initCollateral(
        IStableMaster stableMaster,
        IPoolManager poolManager,
        IPerpetualManager perpetualManager,
        IFeeManager feeManager,
        PoolParameters memory p
    ) external {
        require(msg.sender == owner, "79");
        stableMaster.setUserFees(poolManager, p.xFeeMint, p.yFeeMint, 1);
        stableMaster.setUserFees(poolManager, p.xFeeBurn, p.yFeeBurn, 0);

        perpetualManager.setHAFees(p.xHAFeesDeposit, p.yHAFeesDeposit, 1);
        perpetualManager.setHAFees(p.xHAFeesWithdraw, p.yHAFeesWithdraw, 0);

        feeManager.setFees(p.xSlippageFee, p.ySlippageFee, 0);
        feeManager.setFees(p.xBonusMalusMint, p.yBonusMalusMint, 1);
        feeManager.setFees(p.xBonusMalusBurn, p.yBonusMalusBurn, 2);
        feeManager.setFees(p.xSlippage, p.ySlippage, 3);

        feeManager.setHAFees(p.haFeeDeposit, p.haFeeWithdraw);

        stableMaster.setCapOnStableAndMaxInterests(p.capOnStableMinted, p.maxInterestsDistributed, poolManager);
        stableMaster.setIncentivesForSLPs(p.feesForSLPs, p.interestsForSLPs, poolManager);

        perpetualManager.setTargetAndLimitHAHedge(p.targetHAHedge, p.limitHAHedge);
        perpetualManager.setBoundsPerpetual(p.maxLeverage, p.maintenanceMargin);
        perpetualManager.setLockTime(p.lockTime);
        perpetualManager.setKeeperFeesLiquidationRatio(p.keeperFeesLiquidationRatio);
        perpetualManager.setKeeperFeesCap(p.keeperFeesLiquidationCap, p.keeperFeesClosingCap);
        perpetualManager.setKeeperFeesClosing(p.xKeeperFeesClosing, p.yKeeperFeesClosing);

        feeManager.updateHA();
        feeManager.updateUsersSLP();

        /*
        stableMaster.unpause(keccak256("STABLE"), poolManager);
        stableMaster.unpause(keccak256("SLP"), poolManager);
        perpetualManager.unpause();
        */
    }
}
