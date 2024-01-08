// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

library ArthPoolLibrary {
    using SafeMath for uint256;

    /**
     * Data structs.
     */

    struct MintFAParams {
        uint256 arthxPriceGMU;
        uint256 collateralPriceGMU;
        uint256 arthxAmount;
        uint256 collateralAmount;
        uint256 collateralRatio;
    }

    struct BuybackARTHXParams {
        uint256 excessCollateralGMUValueD18;
        uint256 arthxPriceGMU;
        uint256 collateralPriceGMU;
        uint256 arthxAmount;
    }

    uint256 private constant _PRICE_PRECISION = 1e6;

    /**
     * Public.
     */

    function calcMint1t1ARTH(
        uint256 collateralPrice,
        uint256 collateralAmountD18
    ) public pure returns (uint256) {
        return (collateralAmountD18.mul(collateralPrice)).div(1e6);
    }

    function calcOverCollateralizedMintAmounts(
        uint256 collateralRatio,
        uint256 algorithmicRatio,
        uint256 collateralPrice,
        uint256 arthxPrice,
        uint256 collateralAmountD18
    )
        public
        pure
        returns (
            uint256,  // ARTH Mint amount.
            uint256  // ARTHX Mint amount.
        )
    {
        uint256 collateralValue = (
            collateralAmountD18
            .mul(collateralPrice)
            .div(1e6)
        );

        uint256 arthValueToMint = collateralValue.mul(collateralRatio).div(1e6);
        uint256 arthxValueToMint = collateralValue.mul(algorithmicRatio).div(1e6);

        return (
            arthValueToMint,
            arthxValueToMint.mul(1e6).div(arthxPrice)
        );
    }

    function calcMintAlgorithmicARTH(
        uint256 arthxPriceGMU,
        uint256 collateralAmountD18
    ) public pure returns (uint256) {
        return collateralAmountD18.mul(arthxPriceGMU).div(1e6);
    }

    // Must be internal because of the struct
    function calcMintFractionalARTH(MintFAParams memory params)
        internal
        pure
        returns (uint256, uint256)
    {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint ARTH. We do this by seeing the minimum mintable ARTH based on each amount
        uint256 arthxGMUValueD18;
        uint256 collateralGMUValueD18;

        // Scoping for stack concerns
        {
            // USD amounts of the collateral and the ARTHX
            arthxGMUValueD18 = params.arthxAmount.mul(params.arthxPriceGMU).div(
                1e6
            );
            collateralGMUValueD18 = params
                .collateralAmount
                .mul(params.collateralPriceGMU)
                .div(1e6);
        }
        uint256 calcARTHXGMUValueD18 =
            (collateralGMUValueD18.mul(1e6).div(params.collateralRatio)).sub(
                collateralGMUValueD18
            );

        uint256 calcARTHXNeeded =
            calcARTHXGMUValueD18.mul(1e6).div(params.arthxPriceGMU);

        return (
            collateralGMUValueD18.add(calcARTHXGMUValueD18),
            calcARTHXNeeded
        );
    }

    function calcOverCollateralizedRedeemAmounts(
        uint256 collateralRatio,
        // uint256 algorithmicRatio,
        uint256 arthxPrice,
        uint256 collateralPriceGMU,
        uint256 arthAmount
        //, uint256 arthxAmount
    )
        public
        pure
        returns (
            uint256,  // Collateral amount to return.
            uint256   // ARTHX amount needed.
        )
    {
        // uint256 totalInputValue = arthAmount.add(
        //     arthxAmount.mul(arthxPrice).div(1e6)
        // );

        // // Ensures inputs are in ratios mentioned.
        // require(
        //     totalInputValue.mul(collateralRatio).div(1e6) == arthAmount,
        //     'ArthPoolLibrary: invalid ratios'
        // );
        // require(
        //     totalInputValue.mul(algorithmicRatio).div(1e6) == arthxAmount.mul(arthxPrice).div(1e6),
        //     'ArthPoolLibrary: invalid ratios'
        // );

        // return (
        //     totalInputValue.mul(1e6).div(collateralPriceGMU)
        // );

        uint256 arthxValueNeeded = (
            arthAmount
                .mul(1e6)
                .div(collateralRatio)
                .sub(arthAmount)
        );
        uint256 arthxNeeded = arthxValueNeeded.mul(1e6).div(arthxPrice);

        return (
            arthAmount.add(arthxValueNeeded).mul(1e6).div(collateralPriceGMU),
            arthxNeeded
        );
    }

    function calcRedeem1t1ARTH(uint256 collateralPriceGMU, uint256 arthAmount)
        public
        pure
        returns (uint256)
    {
        return arthAmount.mul(1e6).div(collateralPriceGMU);
    }

    // Must be internal because of the struct
    function calcBuyBackARTHX(BuybackARTHXParams memory params)
        internal
        pure
        returns (uint256)
    {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible ARTHX with the desired collateral
        require(
            params.excessCollateralGMUValueD18 > 0,
            'No excess collateral to buy back!'
        );

        // Make sure not to take more than is available
        uint256 arthxGMUValueD18 =
            params.arthxAmount.mul(params.arthxPriceGMU).div(1e6);
        require(
            arthxGMUValueD18 <= params.excessCollateralGMUValueD18,
            'You are trying to buy back more than the excess!'
        );

        // Get the equivalent amount of collateral based on the market value of ARTHX provided
        uint256 collateralEquivalentD18 =
            arthxGMUValueD18.mul(1e6).div(params.collateralPriceGMU);
        // collateralEquivalentD18 = collateralEquivalentD18.sub((collateralEquivalentD18.mul(params.buybackFee)).div(1e6));

        return (collateralEquivalentD18);
    }

    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(
        uint256 totalSupply,
        uint256 globalCollateralRatio,
        uint256 globalCollatValue
    ) public pure returns (uint256) {
        uint256 targetCollateralValue =
            totalSupply.mul(globalCollateralRatio).div(1e6); // We want 18 decimals of precision so divide by 1e6; totalSupply is 1e18 and globalCollateralRatio is 1e6

        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return targetCollateralValue.sub(globalCollatValue); // If recollateralization is not needed, throws a subtraction underflow
        // return(recollateralization_left);
    }

    function calcRecollateralizeARTHInner(
        uint256 collateralAmount,
        uint256 collateralPrice,
        uint256 globalCollatValue,
        uint256 arthTotalSupply,
        uint256 globalCollateralRatio
    )
        public
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 collateralValueAttempted =
            collateralAmount.mul(collateralPrice).div(1e6);
        uint256 effectiveCollateralRatio =
            globalCollatValue.mul(1e6).div(arthTotalSupply); //returns it in 1e6

        uint256 recollateralizePossible =
            (
                globalCollateralRatio.mul(arthTotalSupply).sub(
                    arthTotalSupply.mul(effectiveCollateralRatio)
                )
            )
                .div(1e6);

        uint256 amountToRecollateralize;
        if (collateralValueAttempted <= recollateralizePossible) {
            amountToRecollateralize = collateralValueAttempted;
        } else {
            amountToRecollateralize = recollateralizePossible;
        }

        return (
            amountToRecollateralize.mul(1e6).div(collateralPrice),
            amountToRecollateralize,
            recollateralizePossible
        );
    }
}
