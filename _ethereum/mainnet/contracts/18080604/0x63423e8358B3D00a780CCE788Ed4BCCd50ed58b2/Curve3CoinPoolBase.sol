// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ICurvePool.sol";
import "./PackedRange.sol";
import "./uint16a16Lib.sol";
import "./Strategy.sol";
import "./CurvePoolBase.sol";

error CurveBeforeDepositCheckFailed();
error CurveBeforeRedeemalCheckFailed();
error CurveDepositSlippagesFailed();
error CurveRedeemSlippagesFailed();
error CurveCompoundSlippagesFailed();

// multiple assets
// slippages
// - mode selection: slippages[0]
// - DHW with deposit: slippages[0] == 0
//   - beforeDepositCheck: slippages[1..6]
//   - beforeRedeemalCheck: slippages[7]
//   - compound: slippages[8]
//   - _depositToProtocol: slippages[9]
// - DHW with withdrawal: slippages[0] == 1
//   - beforeDepositCheck: slippages[1..6]
//   - beforeRedeemalCheck: slippages[7]
//   - compound: slippages[8]
//   - _redeemFromProtocol: slippages[9..11]
// - reallocate: slippages[0] == 2
//   - beforeDepositCheck: depositSlippages[1..6]
//   - _depositToProtocol: depositSlippages[7]
//   - beforeRedeemalCheck: withdrawalSlippages[1]
//   - _redeemFromProtocol: withdrawalSlippages[2..4]
// - redeemFast or emergencyWithdraw: slippages[0] == 3
//   - _redeemFromProtocol or _emergencyWithdrawImpl: slippages[1..3]
abstract contract Curve3CoinPoolBase is CurvePoolBase {
    using SafeERC20 for IERC20;
    using uint16a16Lib for uint16a16;

    uint256 internal constant N_COINS = 3;

    ICurve3CoinPool public pool;

    function __Curve3CoinPoolBase_init(
        string memory strategyName_,
        uint256 assetGroupId_,
        IERC20 lpToken_,
        uint16a16 assetMapping_,
        ICurve3CoinPool pool_,
        int128 positiveYieldLimit_,
        int128 negativeYieldLimit_
    ) internal onlyInitializing {
        pool = pool_;

        __CurvePoolBase_init(
            strategyName_, assetGroupId_, lpToken_, assetMapping_, positiveYieldLimit_, negativeYieldLimit_
        );
    }

    function assetRatio() external view override returns (uint256[] memory) {
        uint256[] memory assetRatio_ = new uint256[](N_COINS);

        for (uint256 i; i < N_COINS; ++i) {
            assetRatio_[i] = _balances(assetMapping.get(i));
        }

        return assetRatio_;
    }

    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts) {
        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());

        uint256 lpTokenBalance = _lpTokenBalance();
        uint256 lpTokenTotalSupply = lpToken.totalSupply();
        amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            amounts[i] = _balances(assetMapping.get(i)) * lpTokenBalance / lpTokenTotalSupply;
        }
    }

    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) public override {
        if (_isViewExecution()) {
            uint256[] memory beforeDepositCheckSlippageAmounts = new uint256[](6);

            for (uint256 i; i < N_COINS; ++i) {
                beforeDepositCheckSlippageAmounts[i] = amounts[i];

                beforeDepositCheckSlippageAmounts[N_COINS + i] = ICurvePoolUint256(address(pool)).balances(i);
            }

            emit BeforeDepositCheckSlippages(beforeDepositCheckSlippageAmounts);
            return;
        }

        if (slippages[0] > 2) {
            revert CurveBeforeDepositCheckFailed();
        }

        for (uint256 i; i < N_COINS; ++i) {
            uint256 poolBalance = ICurvePoolUint256(address(pool)).balances(i);

            if (
                !PackedRange.isWithinRange(slippages[i + 1], amounts[i])
                    || !PackedRange.isWithinRange(slippages[i + 4], poolBalance)
            ) {
                revert CurveBeforeDepositCheckFailed();
            }
        }
    }

    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) public override {
        if (_isViewExecution()) {
            emit BeforeRedeemalCheckSlippages(ssts);
            return;
        }

        uint256 slippage;
        if (slippages[0] < 2) {
            slippage = slippages[7];
        } else if (slippages[0] == 2) {
            slippage = slippages[1];
        } else {
            revert CurveBeforeRedeemalCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippage, ssts)) {
            revert CurveBeforeRedeemalCheckFailed();
        }
    }

    function _depositToProtocol(address[] calldata tokens, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        override
    {
        uint256 slippage;
        if (slippages[0] == 0) {
            slippage = slippages[9];
        } else if (slippages[0] == 2) {
            slippage = slippages[7];
        } else {
            revert CurveDepositSlippagesFailed();
        }

        _depositToCurve(tokens, amounts, slippage);
    }

    function _redeemFromProtocol(address[] calldata, uint256 ssts, uint256[] calldata slippages) internal override {
        uint256 slippageOffset;
        if (slippages[0] == 1) {
            slippageOffset = 9;
        } else if (slippages[0] == 2) {
            slippageOffset = 2;
        } else if (slippages[0] == 3) {
            slippageOffset = 1;
        } else if (slippages[0] == 0 && _isViewExecution()) {
            slippageOffset = 9;
        } else {
            revert CurveRedeemSlippagesFailed();
        }

        uint256 lpTokensToRedeem = _lpTokenBalance() * ssts / totalSupply();
        _redeemFromCurve(lpTokensToRedeem, slippageOffset, slippages);
    }

    function _emergencyWithdrawImpl(uint256[] calldata slippages, address recipient) internal override {
        if (slippages[0] != 3) {
            revert CurveRedeemSlippagesFailed();
        }

        _redeemFromCurve(_lpTokenBalance(), 1, slippages);

        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());

        for (uint256 i; i < N_COINS; ++i) {
            IERC20(tokens[i]).safeTransfer(recipient, IERC20(tokens[i]).balanceOf(address(this)));
        }
    }

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        view
        override
        returns (uint256)
    {
        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());

        uint256 usdWorth;
        uint256 lpTokenBalance = _lpTokenBalance();
        uint256 lpTokenTotalSupply = lpToken.totalSupply();
        for (uint256 i; i < tokens.length; ++i) {
            usdWorth += priceFeedManager.assetToUsdCustomPrice(
                tokens[i], _balances(assetMapping.get(i)) * lpTokenBalance / lpTokenTotalSupply, exchangeRates[i]
            );
        }

        return usdWorth;
    }

    function _depositToCurveCompound(address[] memory tokens, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        override
    {
        if (slippages[0] > 1) {
            revert CurveCompoundSlippagesFailed();
        }

        _depositToCurve(tokens, amounts, slippages[8]);
    }

    function _depositToCurve(address[] memory tokens, uint256[] memory amounts, uint256 slippage) private {
        uint256[N_COINS] memory curveAmounts;

        for (uint256 i; i < N_COINS; ++i) {
            curveAmounts[assetMapping.get(i)] = amounts[i];
            _resetAndApprove(IERC20(tokens[i]), address(pool), amounts[i]);
        }

        pool.add_liquidity(curveAmounts, slippage);

        _handleDeposit();
    }

    function _redeemFromCurve(uint256 lpTokens, uint256 slippageOffset, uint256[] calldata slippages) private {
        _handleWithdrawal(lpTokens);

        uint256[3] memory minOuts;
        for (uint256 i; i < N_COINS; ++i) {
            minOuts[assetMapping.get(i)] = slippages[slippageOffset + i];
        }

        pool.remove_liquidity(lpTokens, minOuts);

        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());
        uint256[] memory bought = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            bought[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        if (_isViewExecution()) {
            emit Slippages(false, 0, abi.encode(bought));
        }
    }

    function _ncoins() internal pure override returns (uint256) {
        return N_COINS;
    }
}
