// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import "./FixedPointMathLib.sol";

// interfaces
import "./IOracle.sol";

import "./constants.sol";
import "./errors.sol";
import "./types.sol";

library FeeLib {
    using FixedPointMathLib for uint256;

    /**
     * @notice Calculates the management and performance fee for the current round
     * @param vaultDetails VaultDetails struct
     * @param managementFee charged at each round
     * @param performanceFee charged if the vault performs
     * @return totalFees all fees taken in round
     * @return balances is the asset balances at the start of the next round
     */
    function processFees(VaultDetails calldata vaultDetails, uint256 managementFee, uint256 performanceFee)
        external
        pure
        returns (uint256[] memory totalFees, uint256[] memory balances)
    {
        uint256 collateralCount = vaultDetails.currentBalances.length;

        totalFees = new uint256[](collateralCount);
        balances = new uint256[](collateralCount);

        for (uint256 i; i < collateralCount;) {
            uint256 lockedBalanceSansPending;
            uint256 managementFeeInAsset;
            uint256 performanceFeeInAsset;

            balances[i] = vaultDetails.currentBalances[i];

            // primary asset amount used to calculating the amount of secondary assets deposited in the round
            uint256 pendingBalance =
                vaultDetails.startingBalances[i].mulDivDown(vaultDetails.totalPending, vaultDetails.startingBalances[0]);

            // At round 1, currentBalance == totalPending so we do not take fee on the first round
            if (balances[i] > pendingBalance) {
                lockedBalanceSansPending = balances[i] - pendingBalance;
            }

            managementFeeInAsset = lockedBalanceSansPending.mulDivDown(managementFee, 100 * PERCENT_MULTIPLIER);

            // Performance fee charged ONLY if difference between starting balance(s) and ending
            // balance(s) (excluding pending depositing) is positive
            // If the balance is negative, the the round did not profit.
            if (lockedBalanceSansPending > vaultDetails.startingBalances[i]) {
                if (performanceFee > 0) {
                    uint256 performanceAmount = lockedBalanceSansPending - vaultDetails.startingBalances[i];

                    performanceFeeInAsset = performanceAmount.mulDivDown(performanceFee, 100 * PERCENT_MULTIPLIER);
                }
            }

            totalFees[i] = managementFeeInAsset + performanceFeeInAsset;

            // deducting fees from current balances
            balances[i] -= totalFees[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates Net Asset Value of the vault and pending deposits
     * @dev prices are based on expiry, if rolling close then spot is used
     * @param details NAVDetails struct
     * @return totalNav of all the assets
     * @return pendingNAV of just the pending assets
     * @return prices of the different assets
     */
    function calculateNAVs(NAVDetails calldata details)
        external
        view
        returns (uint256 totalNav, uint256 pendingNAV, uint256[] memory prices)
    {
        IOracle oracle = IOracle(details.oracleAddr);

        uint256 collateralCount = details.collaterals.length;

        prices = new uint256[](collateralCount);

        // primary asset that all other assets will be quotes in
        address quote = details.collaterals[0].addr;

        for (uint256 i; i < collateralCount;) {
            prices[i] = UNIT;

            // if collateral is primary asset, leave price as 1 (scale 1e6)
            if (i > 0) prices[i] = _getPrice(oracle, details.collaterals[i].addr, quote, details.expiry);

            // sum of all asset(s) value
            totalNav += details.currentBalances[i].mulDivDown(prices[i], 10 ** details.collaterals[i].decimals);

            // calculated pending deposit based on the primary asset
            uint256 pendingBalance = details.totalPending.mulDivDown(details.startingBalances[i], details.startingBalances[0]);

            // sum of pending assets value
            pendingNAV += pendingBalance.mulDivDown(prices[i], 10 ** details.collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice calculates relative Net Asset Value based on the primary asset and a rounds starting balance(s)
     * @dev used in pending deposits per account
     */
    function calculateRelativeNAV(
        Collateral[] memory collaterals,
        uint256[] memory startingBalances,
        uint256[] memory collateralPrices,
        uint256 primaryDeposited
    ) external pure returns (uint256 nav) {
        // primary asset amount used to calculating the amount of secondary assets deposited in the round
        uint256 primaryTotal = startingBalances[0];

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = startingBalances[i].mulDivDown(primaryDeposited, primaryTotal);

            nav += balance.mulDivDown(collateralPrices[i], 10 ** collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    function navToShares(uint256 nav, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= PLACEHOLDER_UINT) revert FL_NPSLow();

        return nav.mulDivDown(UNIT, navPerShare);
    }

    function pricePerShare(uint256 totalSupply, uint256 totalNAV, uint256 pendingNAV) internal pure returns (uint256) {
        return totalSupply > 0 ? (totalNAV - pendingNAV).mulDivDown(UNIT, totalSupply) : UNIT;
    }

    /**
     * @notice get spot price of base, denominated in quote.
     * @dev used in Net Asset Value calculations
     * @dev
     * @param oracle abstracted chainlink oracle
     * @param base base asset. for ETH/USD price, ETH is the base asset
     * @param quote quote asset. for ETH/USD price, USD is the quote asset
     * @param expiry price at a given timestamp
     * @return price with 6 decimals
     */
    function _getPrice(IOracle oracle, address base, address quote, uint256 expiry) internal view returns (uint256 price) {
        // if timestamp is the placeholder (1) or zero then get the spot
        if (expiry <= PLACEHOLDER_UINT) price = oracle.getSpotPrice(base, quote);
        else (price,) = oracle.getPriceAtExpiry(base, quote, expiry);
    }
}
