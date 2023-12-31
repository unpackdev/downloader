// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./Curve3CoinPoolBase.sol";
import "./ConvexStrategy.sol";

contract Convex3poolStrategy is Curve3CoinPoolBase, ConvexStrategy {
    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        uint256 assetGroupId_,
        ISwapper swapper_,
        IBooster booster_
    ) CurvePoolBase(assetGroupRegistry_, accessControl_, assetGroupId_, swapper_) ConvexStrategy(booster_) {}

    function initialize(
        string memory strategyName_,
        ICurve3CoinPool pool_,
        IERC20 lpToken_,
        uint16a16 assetMapping_,
        uint96 pid_,
        bool extraRewards_,
        int128 positiveYieldLimit_,
        int128 negativeYieldLimit_
    ) external initializer {
        __Curve3CoinPoolBase_init(
            strategyName_, NULL_ASSET_GROUP_ID, lpToken_, assetMapping_, pool_, positiveYieldLimit_, negativeYieldLimit_
        );
        __ConvexStrategy_init(pid_, extraRewards_);
    }

    function _coins(uint256 index) internal view override returns (address) {
        return ICurvePoolUint256(address(pool)).coins(index);
    }

    function _balances(uint256 index) internal view override returns (uint256) {
        return ICurvePoolUint256(address(pool)).balances(index);
    }
}
