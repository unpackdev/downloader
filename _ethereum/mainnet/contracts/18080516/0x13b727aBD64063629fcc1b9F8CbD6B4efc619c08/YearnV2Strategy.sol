// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./IYearnTokenVault.sol";
import "./PackedRange.sol";
import "./Strategy.sol";

error YearnV2BeforeDepositCheckFailed();
error YearnV2BeforeRedeemalCheckFailed();
error YearnV2CompoundSlippagesFailed();
error YearnV2DepositToProtocolSlippagesFailed();
error YearnV2RedeemSlippagesFailed();
error YearnV2NotRedeemedEnough();

// only uses one asset
// no rewards
// slippages
// - mode selection: slippages[0]
// - DHW with deposit: slippages[0] == 0
//   - beforeDepositCheck: slippages[1]
//   - beforeRedeemalCheck: slippages[2]
//   - _depositToProtocol: slippages[3]
// - DHW with withdrawal: slippages[0] == 1
//   - beforeDepositCheck: slippages[1]
//   - beforeRedeemalCheck: slippages[2]
//   - _redeemFromProtocol: slippages[3]
// - reallocate: slippages[0] == 2
//   - beforeDepositCheck: depositSlippages[1]
//   - _depositToProtocol: depositSlippages[2]
//   - beforeRedeemalCheck: withdrawalSlippages[1]
//   - _redeemFromProtocol: withdrawalSlippages[2]
// - redeemFast or emergencyWithdraw: slippages[0] == 3
//   - _redeemFromProtocol or _emergencyWithdrawImpl: slippages[1]
contract YearnV2Strategy is Strategy {
    using SafeERC20 for IERC20;

    uint256 constant MAX_BPS = 100_00;

    IYearnTokenVault public yTokenVault;
    uint96 public oneShare;

    uint256 private _lastPricePerShare;

    constructor(IAssetGroupRegistry assetGroupRegistry_, ISpoolAccessControl accessControl_)
        Strategy(assetGroupRegistry_, accessControl_, NULL_ASSET_GROUP_ID)
    {}

    function initialize(string memory name_, uint256 assetGroupId_, IYearnTokenVault yTokenVault_)
        external
        initializer
    {
        __Strategy_init(name_, assetGroupId_);

        if (address(yTokenVault_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        yTokenVault = yTokenVault_;
        oneShare = SafeCast.toUint96(10 ** (yTokenVault_.decimals()));

        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId_);

        if (tokens.length != 1 || tokens[0] != yTokenVault.token()) {
            revert InvalidAssetGroup(assetGroupId_);
        }

        _lastPricePerShare = yTokenVault.pricePerShare();
    }

    function assetRatio() external pure override returns (uint256[] memory) {
        uint256[] memory _assetRatio = new uint256[](1);
        _assetRatio[0] = 1;
        return _assetRatio;
    }

    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts) {
        amounts = new uint256[](1);
        amounts[0] = yTokenVault.balanceOf(address(this)) * yTokenVault.pricePerShare() / oneShare;
    }

    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) public override {
        if (_isViewExecution()) {
            uint256[] memory beforeDepositCheckSlippageAmounts = new uint256[](1);
            beforeDepositCheckSlippageAmounts[0] = amounts[0];

            emit BeforeDepositCheckSlippages(beforeDepositCheckSlippageAmounts);
            return;
        }

        if (slippages[0] > 2) {
            revert YearnV2BeforeDepositCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippages[1], amounts[0])) {
            revert YearnV2BeforeDepositCheckFailed();
        }
    }

    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) public override {
        if (_isViewExecution()) {
            emit BeforeRedeemalCheckSlippages(ssts);
            return;
        }

        uint256 slippage;
        if (slippages[0] < 2) {
            slippage = slippages[2];
        } else if (slippages[0] == 2) {
            slippage = slippages[1];
        } else {
            revert YearnV2BeforeRedeemalCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippage, ssts)) {
            revert YearnV2BeforeRedeemalCheckFailed();
        }
    }

    function _depositToProtocol(address[] calldata tokens, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        override
    {
        uint256 slippage;
        if (slippages[0] == 0) {
            slippage = slippages[3];
        } else if (slippages[0] == 2) {
            slippage = slippages[2];
        } else {
            revert YearnV2DepositToProtocolSlippagesFailed();
        }

        _depositToYearn(tokens[0], amounts[0], slippage);
    }

    function _redeemFromProtocol(address[] calldata, uint256 ssts, uint256[] calldata slippages) internal override {
        uint256 slippage;
        if (slippages[0] == 1) {
            slippage = slippages[3];
        } else if (slippages[0] == 2) {
            slippage = slippages[2];
        } else if (slippages[0] == 3) {
            slippage = slippages[1];
        } else if (_isViewExecution()) {} else {
            revert YearnV2RedeemSlippagesFailed();
        }

        uint256 yearnTokensToRedeem = yTokenVault.balanceOf(address(this)) * ssts / totalSupply();
        _redeemFromYearn(yearnTokensToRedeem, address(this), slippage);
    }

    function _emergencyWithdrawImpl(uint256[] calldata slippages, address recipient) internal override {
        if (slippages[0] != 3) {
            revert YearnV2RedeemSlippagesFailed();
        }

        _redeemFromYearn(yTokenVault.balanceOf(address(this)), recipient, slippages[1]);
    }

    function _compound(address[] calldata, SwapInfo[] calldata, uint256[] calldata)
        internal
        override
        returns (int256 compoundYield)
    {}

    function _getYieldPercentage(int256) internal override returns (int256 baseYieldPercentage) {
        uint256 currentPricePerShare = yTokenVault.pricePerShare();

        baseYieldPercentage = _calculateYieldPercentage(_lastPricePerShare, currentPricePerShare);

        _lastPricePerShare = currentPricePerShare;
    }

    function _swapAssets(address[] memory, uint256[] memory, SwapInfo[] calldata) internal override {}

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        view
        override
        returns (uint256)
    {
        uint256 assetBalance = yTokenVault.balanceOf(address(this)) * yTokenVault.pricePerShare() / oneShare;
        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());

        return priceFeedManager.assetToUsdCustomPrice(tokens[0], assetBalance, exchangeRates[0]);
    }

    function _depositToYearn(address token, uint256 amount, uint256 slippage) private returns (uint256) {
        _resetAndApprove(IERC20(token), address(yTokenVault), amount);

        uint256 mintedYearnTokens = yTokenVault.deposit(amount);

        if (mintedYearnTokens < slippage) {
            revert YearnV2DepositToProtocolSlippagesFailed();
        }

        if (_isViewExecution()) {
            emit Slippages(true, mintedYearnTokens, "");
        }

        return mintedYearnTokens;
    }

    function _redeemFromYearn(uint256 yTokens, address recipient, uint256 slippage) private {
        uint256 balanceBefore = yTokenVault.balanceOf(address(this));

        // we allow for total loss here, since we check slippage ourselves
        uint256 redeemedAssets = yTokenVault.withdraw(yTokens, recipient, MAX_BPS);

        if (redeemedAssets < slippage) {
            revert YearnV2RedeemSlippagesFailed();
        }

        // if Yearn V2 protocol cannot get enough funds, it will not burn all shares
        // if this happens, we should revert
        if (yTokenVault.balanceOf(address(this)) != balanceBefore - yTokens) {
            revert YearnV2NotRedeemedEnough();
        }

        if (_isViewExecution()) {
            emit Slippages(false, redeemedAssets, "");
        }
    }

    function _getProtocolRewardsInternal()
        internal
        virtual
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {}
}
