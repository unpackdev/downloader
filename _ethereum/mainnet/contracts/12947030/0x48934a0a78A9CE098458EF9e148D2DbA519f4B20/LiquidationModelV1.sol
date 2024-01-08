// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./LiquidationModelInterface.sol";
import "./MoartrollerInterface.sol";
import "./MToken.sol";
import "./Moartroller.sol";
import "./SimplePriceOracle.sol";
import "./ExponentialNoError.sol";
import "./Exponential.sol";
import "./ErrorReporter.sol";

// TODO: use custom error reporter
contract LiquidationModelV1 is LiquidationModelInterface, Exponential, MoartrollerErrorReporter {
    /**
         * @notice Calculate number of tokens of collateral asset of the given user to seize given an underlying amount
         * this function takes amount of collateral asset that is locked under protection.
         * @param arguments arguments
         * @return (errorCode, number of mTokenCollateral tokens to be seized in a liquidation)
         */
    function liquidateCalculateSeizeUserTokens(LiquidationModelInterface.LiquidateCalculateSeizeUserTokensArgumentsSet memory arguments) external override view returns (uint, uint) {
        MoartrollerInterface.AccountLiquidityLocalVars memory vars;
        uint oErrGAS;
        (oErrGAS, vars.mTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = MToken(arguments.mTokenCollateral).getAccountSnapshot(arguments.accountForLiquidation);

        uint tokensLockedUnderProtection = arguments.moartroller.getUserLockedAmount(MToken(arguments.mTokenCollateral), arguments.accountForLiquidation);
        (, uint mTokensLockedUnderProtection) = divScalarByExpTruncate(tokensLockedUnderProtection, Exp({mantissa: vars.exchangeRateMantissa}));
//        console.log("MTokens balance          :", vars.mTokenBalance);
//        console.log("Tokens under protection  :", tokensLockedUnderProtection);
//        console.log("MTokens under protection :", mTokensLockedUnderProtection);
        uint oErrST;
        uint seizeTokens;

        (oErrST, seizeTokens) = liquidateCalculateSeizeTokens(arguments);
//        console.log("Seize Mtokens            : ", seizeTokens);

        uint unlockedTokens = vars.mTokenBalance - mTokensLockedUnderProtection;
        if (seizeTokens > unlockedTokens ){
            return (oErrST, unlockedTokens);
        } else {
            return (oErrST, seizeTokens);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in mToken.liquidateBorrowFresh)
     * @param arguments arguments
     * @return (errorCode, number of mTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(LiquidationModelInterface.LiquidateCalculateSeizeUserTokensArgumentsSet memory arguments) public override view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = mul_(
            arguments.oracle.getUnderlyingPrice(MToken(arguments.mTokenBorrowed)),
            10**uint256(18 - EIP20Interface(MToken(arguments.mTokenBorrowed).getUnderlying()).decimals())
        );
        uint priceCollateralMantissa = mul_(
            arguments.oracle.getUnderlyingPrice(MToken(arguments.mTokenCollateral)),
            10**uint256(18 - EIP20Interface(MToken(arguments.mTokenCollateral).getUnderlying()).decimals())
        );
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = MToken(arguments.mTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({mantissa: arguments.liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, arguments.actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }
}