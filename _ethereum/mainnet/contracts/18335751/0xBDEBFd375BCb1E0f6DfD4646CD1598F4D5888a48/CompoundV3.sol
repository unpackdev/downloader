// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./Interfaces.sol";
import "./DefinitiveAssets.sol";

abstract contract CompoundV3 {
    using DefinitiveAssets for IERC20;

    address public immutable COMET_ADDRESS;

    constructor(address _cometAddress) {
        COMET_ADDRESS = _cometAddress;
    }

    function supply(address asset, uint256 amount) internal {
        if (amount > 0) {
            IERC20(asset).resetAndSafeIncreaseAllowance(address(this), COMET_ADDRESS, amount);

            IComet(COMET_ADDRESS).supply(asset, amount);
        }
    }

    function borrow(address asset, uint256 amount) internal {
        if (amount > 0) {
            IComet(COMET_ADDRESS).withdraw(asset, amount);
        }
    }

    /// @dev If `amount` is type(uint256).max, the entire debt balance will be used.
    function repay(address asset, uint256 amount) internal {
        uint256 debtAmount = _getTotalVariableDebt();
        if (amount > debtAmount) {
            return supply(asset, debtAmount);
        }

        return supply(asset, amount);
    }

    /// @dev If `amount` is type(uint256).max, the entire collateral balance will be used.
    function decollateralize(address asset, uint256 amount) internal {
        uint256 collateralAmount = _getTotalCollateral(asset);
        if (amount > collateralAmount) {
            return borrow(asset, collateralAmount);
        }

        return borrow(asset, amount);
    }

    function _getTotalCollateral(address asset) internal view returns (uint256) {
        return IComet(COMET_ADDRESS).collateralBalanceOf(address(this), asset);
    }

    function _getLTV(address asset) internal view returns (uint256) {
        IComet comet = IComet(COMET_ADDRESS);
        (uint256 borrowAmount, uint256 collateralAmount) = (
            comet.borrowBalanceOf(address(this)),
            comet.collateralBalanceOf(address(this), asset)
        );
        (uint256 price, uint256 precision) = _getOraclePrice(asset);

        // LTV Basis Points Precision: 1e4
        return collateralAmount * price == 0 ? 0 : (borrowAmount * 1e4 * precision) / (collateralAmount * price);
    }

    function _getTotalVariableDebt() internal view returns (uint256) {
        return IComet(COMET_ADDRESS).borrowBalanceOf(address(this));
    }

    function _getOraclePrice(address tokenAddress) internal view returns (uint256 price, uint256 precision) {
        (, , address tokenPriceFeed, , , , , ) = IComet(COMET_ADDRESS).getAssetInfoByAddress(tokenAddress);

        return (
            IComet(COMET_ADDRESS).getPrice(tokenPriceFeed),
            1e8 // 1e8 is the precision of the price feed
        );
    }
}
