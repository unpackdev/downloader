// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

/// @title ComputeProfitability
/// @author Angle Core Team
/// @notice Helper contract to get the optimal borrow amount from a set of provided parameters from Aave
library ComputeProfitability {
    struct SCalculateBorrow {
        int256 reserveFactor;
        int256 totalStableDebt;
        int256 totalVariableDebt;
        int256 totalDeposits;
        int256 stableBorrowRate;
        int256 rewardDeposit;
        int256 rewardBorrow;
        int256 strategyAssets;
        int256 guessedBorrowAssets;
        int256 slope1;
        int256 slope2;
        int256 r0;
        int256 uOptimal;
    }

    int256 private constant _BASE_RAY = 10**27;

    /// @notice Computes the Aave utilization ratio
    function _computeUtilization(int256 borrow, SCalculateBorrow memory parameters) internal pure returns (int256) {
        return
            ((parameters.totalStableDebt + parameters.totalVariableDebt + borrow) * _BASE_RAY) /
            (parameters.totalDeposits + borrow);
    }

    /// @notice Computes the derivative of the utilization ratio with respect to the amount borrowed
    function _computeUprime(int256 borrow, SCalculateBorrow memory parameters) internal pure returns (int256) {
        return
            ((parameters.totalDeposits - parameters.totalStableDebt - parameters.totalVariableDebt) * _BASE_RAY) /
            (parameters.totalDeposits + borrow);
    }

    /// @notice Computes the value of the interest rate, its first and second order derivatives
    /// @dev The returned value is in `_BASE_RAY`
    function _calculateInterestPrimes(int256 borrow, SCalculateBorrow memory parameters)
        internal
        pure
        returns (
            int256 interest,
            int256 interestPrime,
            int256 interestPrime2
        )
    {
        int256 newUtilization = _computeUtilization(borrow, parameters);
        int256 denomUPrime = (parameters.totalDeposits + borrow);
        int256 uprime = _computeUprime(borrow, parameters);
        uprime = (uprime * _BASE_RAY) / denomUPrime;
        int256 uprime2nd = -2 * uprime;
        uprime2nd = (uprime2nd * _BASE_RAY) / denomUPrime;
        if (newUtilization < parameters.uOptimal) {
            interest = parameters.r0 + (parameters.slope1 * newUtilization) / parameters.uOptimal;
            interestPrime = (parameters.slope1 * uprime) / parameters.uOptimal;
            interestPrime2 = (parameters.slope1 * uprime2nd) / parameters.uOptimal;
        } else {
            interest =
                parameters.r0 +
                parameters.slope1 +
                (parameters.slope2 * (newUtilization - parameters.uOptimal)) /
                (_BASE_RAY - parameters.uOptimal);
            interestPrime = (parameters.slope2 * uprime) / (_BASE_RAY - parameters.uOptimal);
            interestPrime2 = (parameters.slope2 * uprime2nd) / (_BASE_RAY - parameters.uOptimal);
        }
    }

    /// @notice Computes the value of the revenue, as well as its first and second order derivatives
    function _revenuePrimes(
        int256 borrow,
        SCalculateBorrow memory parameters,
        bool onlyRevenue
    )
        internal
        pure
        returns (
            int256 revenue,
            int256 revenuePrime,
            int256 revenuePrime2nd
        )
    {
        (int256 newRate, int256 newRatePrime, int256 newRatePrime2) = _calculateInterestPrimes(borrow, parameters);

        // 0 order derivative
        int256 proportionStrat = ((borrow + parameters.strategyAssets) * (_BASE_RAY - parameters.reserveFactor)) /
            (borrow + parameters.totalDeposits);
        int256 poolYearlyRevenue = (parameters.totalStableDebt *
            parameters.stableBorrowRate +
            (borrow + parameters.totalVariableDebt) *
            newRate) / _BASE_RAY;

        revenue =
            (proportionStrat * poolYearlyRevenue) /
            _BASE_RAY +
            (borrow * parameters.rewardBorrow) /
            (borrow + parameters.totalVariableDebt) +
            ((borrow + parameters.strategyAssets) * parameters.rewardDeposit) /
            (borrow + parameters.totalDeposits) -
            (borrow * newRate) /
            _BASE_RAY;

        if (!onlyRevenue) {
            // 1st order derivative
            {
                // Computing block per block to avoid stack too deep errors
                int256 proportionStratPrime = ((parameters.totalDeposits - parameters.strategyAssets) *
                    (_BASE_RAY - parameters.reserveFactor)) / (borrow + parameters.totalDeposits);
                proportionStratPrime = (proportionStratPrime * _BASE_RAY) / (borrow + parameters.totalDeposits);
                int256 poolYearlyRevenuePrime = (newRate *
                    _BASE_RAY +
                    (borrow + parameters.totalVariableDebt) *
                    newRatePrime) / _BASE_RAY;

                revenuePrime = ((proportionStratPrime * poolYearlyRevenue + poolYearlyRevenuePrime * proportionStrat) /
                    _BASE_RAY);

                {
                    int256 proportionStratPrime2nd = (-2 * (proportionStratPrime * (_BASE_RAY))) /
                        ((borrow + parameters.totalDeposits));
                    revenuePrime2nd =
                        2 *
                        proportionStratPrime *
                        poolYearlyRevenuePrime +
                        proportionStratPrime2nd *
                        poolYearlyRevenue;
                }
                poolYearlyRevenuePrime =
                    (2 * newRatePrime * _BASE_RAY + (borrow + parameters.totalVariableDebt) * newRatePrime2) /
                    _BASE_RAY;

                revenuePrime2nd = (revenuePrime2nd + poolYearlyRevenuePrime * proportionStrat) / _BASE_RAY;
            }

            int256 costPrime = (newRate * _BASE_RAY + borrow * newRatePrime) / _BASE_RAY;
            int256 rewardBorrowPrime = (parameters.rewardBorrow * (parameters.totalVariableDebt)) /
                (borrow + parameters.totalVariableDebt);
            rewardBorrowPrime = (rewardBorrowPrime * _BASE_RAY) / (borrow + parameters.totalVariableDebt);
            int256 rewardDepositPrime = (parameters.rewardDeposit *
                (parameters.totalDeposits - parameters.strategyAssets)) / (borrow + parameters.totalDeposits);
            rewardDepositPrime = (rewardDepositPrime * _BASE_RAY) / (borrow + parameters.totalDeposits);

            revenuePrime += rewardBorrowPrime + rewardDepositPrime - costPrime;

            // 2nd order derivative
            // Reusing variables for the stack too deep issue
            costPrime = ((2 * newRatePrime * _BASE_RAY) + borrow * newRatePrime2) / _BASE_RAY;
            rewardBorrowPrime = (-2 * rewardBorrowPrime * _BASE_RAY) / (borrow + parameters.totalVariableDebt);
            rewardDepositPrime = (-2 * rewardDepositPrime * _BASE_RAY) / (borrow + parameters.totalDeposits);

            revenuePrime2nd += (rewardBorrowPrime + rewardDepositPrime) - costPrime;
        }
    }

    /// @notice Returns the absolute value of an integer
    function _abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    /// @notice Computes the optimal borrow amount of the strategy depending on Aave protocol parameters
    /// to maximize folding revenues
    /// @dev Performs a newton Raphson approximation to get the zero point of the derivative of the
    /// revenue function of the protocol depending on the amount borrowed
    function computeProfitability(SCalculateBorrow memory parameters) internal pure returns (int256 borrow) {
        (int256 y, , ) = _revenuePrimes(0, parameters, true);
        (int256 revenueWithBorrow, , ) = _revenuePrimes(_BASE_RAY, parameters, true);

        if (revenueWithBorrow <= y) {
            return 0;
        }
        uint256 count;
        int256 borrowInit;
        int256 grad;
        int256 grad2nd;
        borrow = parameters.guessedBorrowAssets;
        // Tolerance is 1% in this method: indeed we're stopping: `_abs(borrowInit - borrow)/ borrowInit < 10**(-2)`
        while (count < 10 && (count == 0 || _abs(borrowInit - borrow) * (10**2 / 5) > borrowInit)) {
            (, grad, grad2nd) = _revenuePrimes(borrow, parameters, false);
            borrowInit = borrow;
            borrow = borrowInit - (grad * _BASE_RAY) / grad2nd;
            count += 1;
        }

        (int256 x, , ) = _revenuePrimes(borrow, parameters, true);
        if (x <= y) {
            borrow = 0;
        }
    }
}
