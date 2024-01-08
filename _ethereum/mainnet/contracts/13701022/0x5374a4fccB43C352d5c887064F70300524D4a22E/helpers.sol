// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "./math.sol";
import "./basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Aave Lending Pool Provider
     */
    AaveLendingPoolProviderInterface internal constant aaveProvider =
        AaveLendingPoolProviderInterface(
            0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        );

    /**
     * @dev Aave Protocol Data Provider
     */
    AaveDataProviderInterface internal constant aaveData =
        AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    /**
     * @dev Aave Referral Code
     */
    uint16 internal constant referralCode = 0;

    /**
     * @dev Checks if collateral is enabled for an asset
     * @param token token address of the asset.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getIsColl(address token) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(
            token,
            address(this)
        );
    }

    /**
     * @dev Get total debt balance & fee for an asset
     * @param token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
     */
    function getPaybackBalance(address token, uint256 rateMode)
        internal
        view
        returns (uint256)
    {
        (, uint256 stableDebt, uint256 variableDebt, , , , , , ) = aaveData
            .getUserReserveData(token, address(this));
        return rateMode == 1 ? stableDebt : variableDebt;
    }

    /**
     * @dev Get total collateral balance for an asset
     * @param token token address of the collateral.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getCollateralBalance(address token)
        internal
        view
        returns (uint256 bal)
    {
        (bal, , , , , , , , ) = aaveData.getUserReserveData(
            token,
            address(this)
        );
    }
}
