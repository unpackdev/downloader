// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.4;

import "./IMorpho.sol";
import "./Types.sol";
import "./CompoundMath.sol";

contract MorphoChecker {
    using CompoundMath for uint256;

    function isLiquidatable(
        IMorpho _morpho,
        address _user,
        address _poolTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) external view returns (bool) {
        ICompoundOracle oracle = ICompoundOracle(_morpho.comptroller().oracle());
        address[] memory enteredMarkets = _morpho.getEnteredMarkets(_user);
        uint256 numberOfEnteredMarkets = enteredMarkets.length;

        Types.AssetLiquidityData memory assetData;
        uint256 maxDebtValue;
        uint256 debtValue;
        uint256 i;

        while (i < numberOfEnteredMarkets) {
            address poolTokenEntered = enteredMarkets[i];

            assetData = _getUserLiquidityDataForAsset(_morpho, _user, poolTokenEntered, oracle);
            maxDebtValue += assetData.maxDebtValue;
            debtValue += assetData.debtValue;

            if (_poolTokenAddress == poolTokenEntered) {
                if (_borrowedAmount > 0)
                    debtValue += _borrowedAmount.mul(assetData.underlyingPrice);

                if (_withdrawnAmount > 0)
                    maxDebtValue -= _withdrawnAmount.mul(assetData.underlyingPrice).mul(
                        assetData.collateralFactor
                    );
            }

            unchecked {
                ++i;
            }
        }

        return debtValue > maxDebtValue;
    }

    function _getUserLiquidityDataForAsset(
        IMorpho _morpho,
        address _user,
        address _poolTokenAddress,
        ICompoundOracle _oracle
    ) internal view returns (Types.AssetLiquidityData memory assetData) {
        assetData.underlyingPrice = _oracle.getUnderlyingPrice(_poolTokenAddress);
        if (assetData.underlyingPrice == 0) revert("CompoundOracleFailed");
        (, assetData.collateralFactor, ) = _morpho.comptroller().markets(_poolTokenAddress);

        assetData.collateralValue = _getUserSupplyBalanceInOf(_morpho, _poolTokenAddress, _user)
            .mul(assetData.underlyingPrice);
        assetData.debtValue = _getUserBorrowBalanceInOf(_morpho, _poolTokenAddress, _user).mul(
            assetData.underlyingPrice
        );
        assetData.maxDebtValue = assetData.collateralValue.mul(assetData.collateralFactor);
    }

    function _getUserSupplyBalanceInOf(
        IMorpho _morpho,
        address _poolTokenAddress,
        address _user
    ) internal view returns (uint256) {
        Types.SupplyBalance memory userSupplyBalance = _morpho.supplyBalanceInOf(
            _poolTokenAddress,
            _user
        );
        return
            userSupplyBalance.inP2P.mul(_morpho.p2pSupplyIndex(_poolTokenAddress)) +
            userSupplyBalance.onPool.mul(ICToken(_poolTokenAddress).exchangeRateStored());
    }

    function _getUserBorrowBalanceInOf(
        IMorpho _morpho,
        address _poolTokenAddress,
        address _user
    ) internal view returns (uint256) {
        Types.BorrowBalance memory userBorrowBalance = _morpho.borrowBalanceInOf(
            _poolTokenAddress,
            _user
        );
        return
            userBorrowBalance.inP2P.mul(_morpho.p2pBorrowIndex(_poolTokenAddress)) +
            userBorrowBalance.onPool.mul(ICToken(_poolTokenAddress).borrowIndex());
    }
}
