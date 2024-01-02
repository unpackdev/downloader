// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./IERC20.sol";

import { IAToken }           from "lib/aave-v3-core/contracts/interfaces/IAToken.sol";
import "./IPoolDataProvider.sol";
import { IPool }             from "lib/aave-v3-core/contracts/interfaces/IPool.sol";

contract SparkLendHealthChecker {

    IPool             pool;
    IPoolDataProvider dataProvider;

    struct ReserveAssetLiability {
        address reserve;
        uint256 assets;
        uint256 liabilities;
    }

    constructor(address pool_, address dataProvider_) {
        pool         = IPool(pool_);
        dataProvider = IPoolDataProvider(dataProvider_);
    }

    function runChecks() public pure returns (bool) {
        return true;
    }

    // NOTE: All diffs are expressed as 1e18 precision.
    function getAllReservesAssetLiability()
        public view returns (ReserveAssetLiability[] memory reserveData)
    {
        IPoolDataProvider.TokenData[] memory tokenData = dataProvider.getAllReservesTokens();

        // TODO: Update name
        reserveData = new ReserveAssetLiability[](tokenData.length);

        for (uint256 i = 0; i < tokenData.length; i++) {
            address reserve = tokenData[i].tokenAddress;

            ( uint256 assets, uint256 liabilities ) = getReserveAssetLiability(reserve);

            reserveData[i] = ReserveAssetLiability(reserve, assets, liabilities);
        }
    }

    // NOTE: All diffs are expressed as 1e18 precision.
    function getReserveAssetLiability(address asset)
        public view returns (uint256 assets, uint256 liabilities)
    {
        ( , uint256 accruedToTreasuryScaled,,,,,,,,,, )
            = dataProvider.getReserveData(asset);

        ( address aToken,, ) = dataProvider.getReserveTokensAddresses(asset);

        uint256 totalDebt         = dataProvider.getTotalDebt(asset);
        uint256 totalLiquidity    = IERC20(asset).balanceOf(aToken);
        uint256 scaledLiabilities = IAToken(aToken).scaledTotalSupply() + accruedToTreasuryScaled;

        assets      = totalLiquidity + totalDebt;
        liabilities = scaledLiabilities * pool.getReserveNormalizedIncome(asset) / 1e27;

        uint256 precision = 10 ** IERC20(asset).decimals();

        assets      = assets      * 1e18 / precision;
        liabilities = liabilities * 1e18 / precision;
    }

    // TODO: Investigate if oracles should be a concern here since they are being used to calculate
    //       the base values.
    function getUserHealth(address user)
        public view returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            bool belowLiquidationThreshold
        )
    {
        (
            totalCollateralBase,
            totalDebtBase,
            availableBorrowsBase,
            currentLiquidationThreshold,
            ltv,
            healthFactor
        ) = pool.getUserAccountData(user);

        belowLiquidationThreshold = healthFactor < 1e18;
    }

}
