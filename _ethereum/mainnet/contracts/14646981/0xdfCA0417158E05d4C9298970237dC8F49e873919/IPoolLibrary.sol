// SPDX-License-Identifier: GPL-3.0-or-later

interface IPoolLibrary {
     struct MintFractionalDeiParams {
        uint256 deusPrice;
        uint256 collateralPrice;
        uint256 collateralAmount;
        uint256 collateralRatio;
    }

    struct BuybackDeusParams {
        uint256 excessCollateralValueD18;
        uint256 deusPrice;
        uint256 collateralPrice;
        uint256 deusAmount;
    }

    function calcMint1t1DEI(uint256 col_price, uint256 collateral_amount_d18)
        external
        pure
        returns (uint256);

    function calcMintAlgorithmicDEI(
        uint256 deus_price_usd,
        uint256 deus_amount_d18
    ) external pure returns (uint256);

    function calcMintFractionalDEI(MintFractionalDeiParams memory params)
        external
        pure
        returns (uint256, uint256);

    function calcRedeem1t1DEI(uint256 col_price_usd, uint256 DEI_amount)
        external
        pure
        returns (uint256);

    function calcBuyBackDEUS(BuybackDeusParams memory params)
        external
        pure
        returns (uint256);

    function recollateralizeAmount(
        uint256 total_supply,
        uint256 global_collateral_ratio,
        uint256 global_collat_value
    ) external pure returns (uint256);

    function calcRecollateralizeDEIInner(
        uint256 collateral_amount,
        uint256 col_price,
        uint256 global_collat_value,
        uint256 dei_total_supply,
        uint256 global_collateral_ratio
    ) external pure returns (uint256, uint256);
}
