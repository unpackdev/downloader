// SPDX-License-Identifier: MITs
pragma solidity 0.8.18;

import "./SafeMathUpgradeable.sol";
import "./DataTypes.sol";
import "./Errors.sol";
import "./ITroveManager.sol";
import "./ITroveDebt.sol";
import "./ITroveInterestRateStrategy.sol";
import "./IUSDEToken.sol";
import "./ERDMath.sol";
import "./WadRayMath.sol";

library TroveLogic {
    using SafeMathUpgradeable for uint256;
    using WadRayMath for uint256;

    using TroveLogic for DataTypes.TroveData;

    /**
     * @dev Emitted when the state of a trove is updated
     * @param borrowRate The new borrow rate
     * @param borrowIndex The new borrow index
     **/
    event TroveDataUpdated(uint256 borrowRate, uint256 borrowIndex);

    /**
     * @dev Returns the ongoing normalized debt for the trove
     * A value of 1e27 means there is no debt. As time passes, the income is accrued
     * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
     * @param trove The trove object
     * @return The normalized debt. expressed in ray
     **/
    function getNormalizedDebt(
        DataTypes.TroveData storage trove
    ) internal view returns (uint256) {
        uint40 timestamp = trove.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == uint40(block.timestamp)) {
            //if the index was updated in the same block, no need to perform any calculation
            return trove.borrowIndex;
        }

        uint256 cumulated = ERDMath
            .calculateCompoundedInterest(trove.currentBorrowRate, timestamp)
            .rayMul(trove.borrowIndex);

        return cumulated;
    }

    /**
     * @dev Updates the liquidity cumulative index and the borrow index, minting accumulated interest to the treasury.
     * @param trove the trove object
     **/
    function updateState(DataTypes.TroveData storage trove) internal {
        uint256 scaledDebt = ITroveDebt(trove.troveDebtAddress)
            .scaledTotalSupply();
        uint256 previousBorrowIndex = trove.borrowIndex;
        uint40 lastUpdatedTimestamp = trove.lastUpdateTimestamp;

        uint256 newBorrowIndex = _updateIndexes(
            trove,
            scaledDebt,
            previousBorrowIndex,
            lastUpdatedTimestamp
        );

        _mintToTreasury(trove, scaledDebt, previousBorrowIndex, newBorrowIndex);
    }

    /**
     * @dev Updates the trove the current borrow rate
     * @param trove The address of the trove to be updated
     **/
    function updateInterestRates(DataTypes.TroveData storage trove) internal {
        uint256 newRate = ITroveInterestRateStrategy(trove.interestRateAddress)
            .calculateInterestRates();
        if (newRate > type(uint128).max) {
            revert Errors.TM_BadBorrowRate();
        }

        trove.currentBorrowRate = uint128(newRate);

        emit TroveDataUpdated(newRate, trove.borrowIndex);
    }

    struct MintToTreasuryLocalVars {
        uint256 currentDebt;
        uint256 previousDebt;
        uint256 totalDebtAccrued;
        uint256 amountToMint;
        uint256 troveFactor;
        uint40 stableSupplyUpdatedTimestamp;
    }

    /**
     * @dev Mints part of the repaid interest to the treasury as a function of the troveFactor for the
     * USDE.
     * @param trove The trove to be updated
     * @param scaledDebt The current scaled total debt
     * @param previousBorrowIndex The borrow index before the last accumulation of the interest
     * @param newBorrowIndex The borrow index after the last accumulation of the interest
     **/
    function _mintToTreasury(
        DataTypes.TroveData storage trove,
        uint256 scaledDebt,
        uint256 previousBorrowIndex,
        uint256 newBorrowIndex
    ) internal {
        MintToTreasuryLocalVars memory vars;

        //calculate the last principal variable debt
        vars.previousDebt = scaledDebt.rayMul(previousBorrowIndex);

        //calculate the new total supply after accumulation of the index
        vars.currentDebt = scaledDebt.rayMul(newBorrowIndex);

        //debt accrued is the sum of the current debt minus the sum of the debt at the last update
        vars.totalDebtAccrued = vars.currentDebt.sub(vars.previousDebt);

        vars.amountToMint = vars.totalDebtAccrued;

        if (vars.amountToMint != 0) {
            IUSDEToken(trove.usdeTokenAddress).mintToTreasury(
                vars.amountToMint,
                trove.factor
            );
        }
    }

    /**
     * @dev Updates the trove indexes and the timestamp of the update
     * @param trove The trove to be updated
     * @param scaledDebt The scaled debt
     * @param borrowIndex The last stored borrow index
     **/
    function _updateIndexes(
        DataTypes.TroveData storage trove,
        uint256 scaledDebt,
        uint256 borrowIndex,
        uint40 timestamp
    ) internal returns (uint256) {
        uint256 newBorrowIndex = borrowIndex;

        //we need to ensure that there is actual debt before accumulating
        if (scaledDebt != 0) {
            uint256 cumulatedBorrowInterest = ERDMath
                .calculateCompoundedInterest(
                    trove.currentBorrowRate,
                    timestamp
                );
            newBorrowIndex = cumulatedBorrowInterest.rayMul(borrowIndex);
            if (newBorrowIndex > type(uint128).max) {
                revert Errors.TM_BadBorrowIndex();
            }
            trove.borrowIndex = uint128(newBorrowIndex);
        }

        //solium-disable-next-line
        trove.lastUpdateTimestamp = uint40(block.timestamp);
        return newBorrowIndex;
    }
}
