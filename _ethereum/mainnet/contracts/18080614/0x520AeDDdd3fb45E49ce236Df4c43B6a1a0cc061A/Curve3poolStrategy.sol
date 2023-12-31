// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ICurveGauge.sol";
import "./ICurveMinter.sol";
import "./Curve3CoinPoolBase.sol";

contract Curve3poolStrategy is Curve3CoinPoolBase {
    ICurveGauge public gauge;
    ICurveMinter public minter;
    address public rewardToken;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        uint256 assetGroupId_,
        ISwapper swapper_
    ) CurvePoolBase(assetGroupRegistry_, accessControl_, assetGroupId_, swapper_) {}

    function initialize(
        string memory strategyName_,
        ICurve3CoinPool pool_,
        uint16a16 assetMapping_,
        ICurveGauge gauge_,
        int128 positiveYieldLimit_,
        int128 negativeYieldLimit_
    ) external initializer {
        __Curve3CoinPoolBase_init(
            strategyName_,
            NULL_ASSET_GROUP_ID,
            IERC20(gauge_.lp_token()),
            assetMapping_,
            pool_,
            positiveYieldLimit_,
            negativeYieldLimit_
        );

        if (address(gauge_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        gauge = gauge_;
        minter = ICurveMinter(gauge_.minter());
        rewardToken = gauge_.crv_token();
    }

    function _coins(uint256 index) internal view override returns (address) {
        return ICurvePoolUint256(address(pool)).coins(index);
    }

    function _balances(uint256 index) internal view override returns (uint256) {
        return ICurvePoolUint256(address(pool)).balances(index);
    }

    function _lpTokenBalance() internal view override returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    function _handleDeposit() internal override {
        uint256 lpTokens = lpToken.balanceOf(address(this));

        _resetAndApprove(lpToken, address(gauge), lpTokens);

        gauge.deposit(lpTokens);

        if (_isViewExecution()) {
            emit Slippages(true, lpTokens, "");
        }
    }

    function _handleWithdrawal(uint256 lpTokens) internal override {
        gauge.withdraw(lpTokens);
    }

    function _getRewards() internal override returns (address[] memory) {
        address[] memory rewards = new address[](1);
        rewards[0] = rewardToken;

        minter.mint(address(gauge));

        return rewards;
    }
}
