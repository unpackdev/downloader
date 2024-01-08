// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers.sol";
import "./interfaces.sol";

contract InteropAaveResolver is Helpers {
    function checkAavePosition(
        address userAddress,
        Position memory position,
        uint256 safeRatioPercentage,
        bool isTarget
    ) public view returns(PositionData memory p) {
        (
            p.isOk,
            p.ltv,
            p.currentLiquidationThreshold
        ) = isPositionSafe(userAddress, safeRatioPercentage);
        p.isOk = isTarget ? true : p.isOk;
        if (!p.isOk) return p;

        p = _checkRatio(userAddress, position, safeRatioPercentage, isTarget);
        if (!p.isOk) return p;
    }

    function checkLiquidity(
        address liquidityAddress,
        address[] memory tokens,
        uint256 totalSupply,
        uint256 totalBorrow,
        uint256 safeLiquidityRatioPercentage,
        bool isTarget
    )
    public view returns(PositionData memory p) {
         (
            p.isOk,
            p.ltv,
            p.currentLiquidationThreshold
        ) = isPositionSafe(liquidityAddress, safeLiquidityRatioPercentage);
        if (!p.isOk) return p;

        p = _checkLiquidityRatio(
            liquidityAddress,
            tokens,
            safeLiquidityRatioPercentage,
            isTarget ? totalSupply :  totalBorrow
        );
        if (!p.isOk) return p;
    }

    constructor (
        address _aaveLendingPoolAddressesProvider,
        address _aaveProtocolDataProvider,
        address _instaIndex,
        address _wnativeToken
    ) Helpers (
        _aaveLendingPoolAddressesProvider,
        _aaveProtocolDataProvider,
        _instaIndex,
        _wnativeToken
    ){}
}