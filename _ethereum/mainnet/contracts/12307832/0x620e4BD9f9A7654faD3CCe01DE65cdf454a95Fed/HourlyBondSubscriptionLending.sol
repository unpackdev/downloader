// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./BaseLending.sol";

struct HourlyBond {
    uint256 amount;
    uint256 yieldQuotientFP;
    uint256 moduloHour;
}

/// @title Here we offer subscriptions to auto-renewing hourly bonds
/// Funds are locked in for an 50 minutes per hour, while interest rates float
abstract contract HourlyBondSubscriptionLending is BaseLending {
    mapping(address => YieldAccumulator) hourlyBondYieldAccumulators;

    uint256 constant RATE_UPDATE_WINDOW = 10 minutes;
    uint256 public withdrawalWindow = 20 minutes;
    uint256 constant MAX_HOUR_UPDATE = 4;
    // issuer => holder => bond record
    mapping(address => mapping(address => HourlyBond))
        public hourlyBondAccounts;

    uint256 public borrowingFactorPercent = 200;

    uint256 constant borrowMinAPR = 6;
    uint256 constant borrowMinHourlyYield =
        FP48 + (borrowMinAPR * FP48) / 100 / hoursPerYear;

    function _makeHourlyBond(
        address issuer,
        address holder,
        uint256 amount
    ) internal {
        HourlyBond storage bond = hourlyBondAccounts[issuer][holder];
        updateHourlyBondAmount(issuer, bond);

        YieldAccumulator storage yieldAccumulator =
            hourlyBondYieldAccumulators[issuer];
        bond.yieldQuotientFP = yieldAccumulator.accumulatorFP;
        if (bond.amount == 0) {
            bond.moduloHour = block.timestamp % (1 hours);
        }
        bond.amount += amount;
        lendingMeta[issuer].totalLending += amount;
    }

    function updateHourlyBondAmount(address issuer, HourlyBond storage bond)
        internal
    {
        uint256 yieldQuotientFP = bond.yieldQuotientFP;
        if (yieldQuotientFP > 0) {
            YieldAccumulator storage yA =
                getUpdatedHourlyYield(
                    issuer,
                    hourlyBondYieldAccumulators[issuer],
                    RATE_UPDATE_WINDOW
                );

            uint256 oldAmount = bond.amount;

            bond.amount = applyInterest(
                bond.amount,
                yA.accumulatorFP,
                yieldQuotientFP
            );

            uint256 deltaAmount = bond.amount - oldAmount;
            lendingMeta[issuer].totalLending += deltaAmount;
        }
    }

    // Retrieves bond balance for issuer and holder
    function viewHourlyBondAmount(address issuer, address holder)
        public
        view
        returns (uint256)
    {
        HourlyBond storage bond = hourlyBondAccounts[issuer][holder];
        uint256 yieldQuotientFP = bond.yieldQuotientFP;

        uint256 cumulativeYield =
            viewCumulativeYieldFP(
                hourlyBondYieldAccumulators[issuer],
                block.timestamp
            );

        if (yieldQuotientFP > 0) {
            return applyInterest(bond.amount, cumulativeYield, yieldQuotientFP);
        } else {
            return bond.amount;
        }
    }

    function _withdrawHourlyBond(
        address issuer,
        HourlyBond storage bond,
        uint256 amount
    ) internal {
        // how far the current hour has advanced (relative to acccount hourly clock)
        uint256 currentOffset = (block.timestamp - bond.moduloHour) % (1 hours);

        require(
            withdrawalWindow >= currentOffset,
            "Tried withdrawing outside subscription cancellation time window"
        );

        bond.amount -= amount;
        lendingMeta[issuer].totalLending -= amount;
    }

    function calcCumulativeYieldFP(
        YieldAccumulator storage yieldAccumulator,
        uint256 timeDelta
    ) internal view returns (uint256 accumulatorFP) {
        uint256 secondsDelta = timeDelta % (1 hours);
        // linearly interpolate interest for seconds
        // FP * FP * 1 / (FP * 1) = FP
        accumulatorFP =
            yieldAccumulator.accumulatorFP +
            (yieldAccumulator.accumulatorFP *
                (yieldAccumulator.hourlyYieldFP - FP48) *
                secondsDelta) /
            (FP48 * 1 hours);

        uint256 hoursDelta = timeDelta / (1 hours);
        if (hoursDelta > 0) {
            uint256 accumulatorBeforeFP = accumulatorFP;
            for (uint256 i = 0; hoursDelta > i && MAX_HOUR_UPDATE > i; i++) {
                // FP48 * FP48 / FP48 = FP48
                accumulatorFP =
                    (accumulatorFP * yieldAccumulator.hourlyYieldFP) /
                    FP48;
            }

            // a lot of time has passed
            if (hoursDelta > MAX_HOUR_UPDATE) {
                // apply interest in non-compounding way
                accumulatorFP +=
                    ((accumulatorFP - accumulatorBeforeFP) *
                        (hoursDelta - MAX_HOUR_UPDATE)) /
                    MAX_HOUR_UPDATE;
            }
        }
    }

    /// @dev updates yield accumulators for both borrowing and lending
    /// issuer address represents a token
    function updateHourlyYield(address issuer)
        public
        returns (uint256 hourlyYield)
    {
        return
            getUpdatedHourlyYield(
                issuer,
                hourlyBondYieldAccumulators[issuer],
                RATE_UPDATE_WINDOW
            )
                .hourlyYieldFP;
    }

    /// @dev updates yield accumulators for both borrowing and lending
    function getUpdatedHourlyYield(
        address issuer,
        YieldAccumulator storage accumulator,
        uint256 window
    ) internal returns (YieldAccumulator storage) {
        uint256 lastUpdated = accumulator.lastUpdated;
        uint256 timeDelta = (block.timestamp - lastUpdated);

        if (timeDelta > window) {
            YieldAccumulator storage borrowAccumulator =
                borrowYieldAccumulators[issuer];

            accumulator.accumulatorFP = calcCumulativeYieldFP(
                accumulator,
                timeDelta
            );

            LendingMetadata storage meta = lendingMeta[issuer];

            accumulator.hourlyYieldFP = currentLendingRateFP(
                meta.totalLending,
                meta.totalBorrowed
            );
            accumulator.lastUpdated = block.timestamp;

            updateBorrowYieldAccu(borrowAccumulator);

            borrowAccumulator.hourlyYieldFP = max(
                borrowMinHourlyYield,
                FP48 +
                    (borrowingFactorPercent *
                        (accumulator.hourlyYieldFP - FP48)) /
                    100
            );
        }

        return accumulator;
    }

    function updateBorrowYieldAccu(YieldAccumulator storage borrowAccumulator)
        internal
    {
        uint256 timeDelta = block.timestamp - borrowAccumulator.lastUpdated;

        if (timeDelta > RATE_UPDATE_WINDOW) {
            borrowAccumulator.accumulatorFP = calcCumulativeYieldFP(
                borrowAccumulator,
                timeDelta
            );

            borrowAccumulator.lastUpdated = block.timestamp;
        }
    }

    function getUpdatedBorrowYieldAccuFP(address issuer)
        external
        returns (uint256)
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        updateBorrowYieldAccu(yA);
        return yA.accumulatorFP;
    }

    function viewCumulativeYieldFP(
        YieldAccumulator storage yA,
        uint256 timestamp
    ) internal view returns (uint256) {
        uint256 timeDelta = (timestamp - yA.lastUpdated);
        if (timeDelta > RATE_UPDATE_WINDOW) {
            return calcCumulativeYieldFP(yA, timeDelta);
        } else {
            return yA.accumulatorFP;
        }
    }
}
