// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IBaseRewardPool.sol";
import "./IBooster.sol";
import "./PackedRange.sol";
import "./CurveAdapter.sol";
import "./Strategy.sol";
import "./StrategyManualYieldVerifier.sol";

error StratBeforeDepositCheckFailed();
error StratBeforeRedeemalCheckFailed();
error StratDepositSlippagesFailed();
error StratRedeemSlippagesFailed();
error StratCompoundSlippagesFailed();

// multiple assets
// multiple rewards
// slippages
// - mode selection: slippages[0]
// - DHW with deposit: slippages[0] == 0
//   - beforeDepositCheck: slippages[1..8]
//   - beforeRedeemalCheck: slippages[9]
//   - compound: slippages[10]
//   - _depositToProtocol: slippages[11]
// - DHW with withdrawal: slippages[0] == 1
//   - beforeDepositCheck: slippages[1..8]
//   - beforeRedeemalCheck: slippages[9]
//   - compound: slippages[10]
//   - _redeemFromProtocol: slippages[11..13]
// - reallocate: slippages[0] == 2
//   - beforeDepositCheck: depositSlippages[1..8]
//   - _depositToProtocol: depositSlippages[9]
//   - beforeRedeemalCheck: withdrawalSlippages[1]
//   - _redeemFromProtocol: withdrawalSlippages[2..4]
// - redeemFast or emergencyWithdraw: slippages[0] == 3
//   - _redeemFromProtocol or _emergencyWithdrawImpl: slippages[1..3]
contract ConvexAlusdStrategy is
    StrategyManualYieldVerifier,
    Strategy,
    CurveMetaPoolAdapter,
    Curve3CoinPoolAdapter,
    CurveUint256PoolAdapter
{
    using SafeERC20 for IERC20;
    using uint16a16Lib for uint16a16;

    uint256 public tokenLength;

    ISwapper public immutable swapper;

    address private _pool;
    address private _lpToken;
    uint16a16 _assetMapping;

    address private _poolMeta;
    uint256 private _oneLpToken;

    uint256 constant BASE_REWARD_COUNT = 2;
    IBooster public immutable booster;
    IBaseRewardPool public crvRewards;
    address public crvRewardToken;
    address public cvxRewardToken;
    uint96 public pid;
    bool extraRewards;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        uint256 assetGroupId_,
        ISwapper swapper_,
        IBooster booster_,
        int128 coinIndexBase_
    ) Strategy(assetGroupRegistry_, accessControl_, assetGroupId_) CurveMetaPoolAdapter(coinIndexBase_) {
        swapper = swapper_;
        booster = booster_;
    }

    function initialize(
        string memory strategyName_,
        address pool_,
        address lpToken_,
        uint16a16 assetMapping_,
        address poolMeta_,
        uint96 pid_,
        bool extraRewards_,
        int128 positiveYieldLimit_,
        int128 negativeYieldLimit_
    ) external initializer {
        __Strategy_init(strategyName_, NULL_ASSET_GROUP_ID);

        _noAddressZero(pool_);
        _noAddressZero(lpToken_);
        _noAddressZero(poolMeta_);

        _pool = pool_;
        _lpToken = lpToken_;
        _assetMapping = assetMapping_;

        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());
        if (tokens.length != N_COINS) {
            revert InvalidAssetGroup(assetGroupId());
        }

        unchecked {
            for (uint256 i; i < tokens.length; ++i) {
                if (tokens[i] != _coins(i)) {
                    revert InvalidAssetGroup(assetGroupId());
                }
            }
        }

        tokenLength = tokens.length;

        _poolMeta = poolMeta_;
        _oneLpToken = 10 ** IERC20Metadata(_poolMeta).decimals();

        pid = pid_;
        extraRewards = extraRewards_;
        crvRewards = IBaseRewardPool(booster.poolInfo(pid_).crvRewards);
        crvRewardToken = crvRewards.rewardToken();
        cvxRewardToken = booster.minter();

        _setPositiveYieldLimit(positiveYieldLimit_);
        _setNegativeYieldLimit(negativeYieldLimit_);
    }

    // adapters

    function pool() public view override(Curve3CoinPoolAdapter, CurveUint256PoolAdapter) returns (address) {
        return _pool;
    }

    function poolMeta() public view override returns (address) {
        return _poolMeta;
    }

    function assetMapping() public view override(Curve3CoinPoolAdapter, CurveUint256PoolAdapter) returns (uint16a16) {
        return _assetMapping;
    }

    // strategy

    function assetRatio() external view override returns (uint256[] memory) {
        uint256[] memory assetRatio_ = new uint256[](tokenLength);

        unchecked {
            for (uint256 i; i < tokenLength; ++i) {
                assetRatio_[i] = _balances(i);
            }
        }

        return assetRatio_;
    }

    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts) {
        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());
        amounts = _getTokenWorth(tokens);
    }

    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) public override {
        unchecked {
            if (_isViewExecution()) {
                uint256[] memory beforeDepositCheckSlippageAmounts = new uint256[](8);

                for (uint256 i; i < tokenLength; ++i) {
                    beforeDepositCheckSlippageAmounts[i] = amounts[i];
                    beforeDepositCheckSlippageAmounts[i + 3] = ICurvePoolUint256(address(_pool)).balances(i);
                }
                for (uint256 i; i < N_COINS_META; ++i) {
                    beforeDepositCheckSlippageAmounts[i + 6] = ICurvePoolUint256(address(_poolMeta)).balances(i);
                }

                emit BeforeDepositCheckSlippages(beforeDepositCheckSlippageAmounts);
                return;
            }

            if (slippages[0] > 2) {
                revert StratBeforeDepositCheckFailed();
            }

            for (uint256 i; i < tokenLength; ++i) {
                if (!PackedRange.isWithinRange(slippages[i + 1], amounts[i])) {
                    revert StratBeforeDepositCheckFailed();
                }
            }

            for (uint256 i; i < N_COINS; ++i) {
                if (!PackedRange.isWithinRange(slippages[i + 4], ICurvePoolUint256(address(_pool)).balances(i))) {
                    revert StratBeforeDepositCheckFailed();
                }
            }

            for (uint256 i; i < N_COINS_META; ++i) {
                if (!PackedRange.isWithinRange(slippages[i + 7], ICurvePoolUint256(address(_poolMeta)).balances(i))) {
                    revert StratBeforeDepositCheckFailed();
                }
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
            slippage = slippages[9];
        } else if (slippages[0] == 2) {
            slippage = slippages[1];
        } else {
            revert StratBeforeRedeemalCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippage, ssts)) {
            revert StratBeforeRedeemalCheckFailed();
        }
    }

    function _depositToProtocol(address[] calldata tokens, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        override
    {
        uint256 slippage;
        if (slippages[0] == 0) {
            slippage = slippages[11];
        } else if (slippages[0] == 2) {
            slippage = slippages[9];
        } else {
            revert StratDepositSlippagesFailed();
        }

        _depositInner(tokens, amounts, slippage);
    }

    function _redeemFromProtocol(address[] calldata, uint256 ssts, uint256[] calldata slippages) internal override {
        uint256 slippageOffset;
        if (slippages[0] == 1) {
            slippageOffset = 11;
        } else if (slippages[0] == 2) {
            slippageOffset = 2;
        } else if (slippages[0] == 3) {
            slippageOffset = 1;
        } else if (slippages[0] == 0 && _isViewExecution()) {
            slippageOffset = 11;
        } else {
            revert StratRedeemSlippagesFailed();
        }

        _redeemInner(ssts, slippages, slippageOffset);
    }

    function _emergencyWithdrawImpl(uint256[] calldata slippages, address recipient) internal override {
        if (slippages[0] != 3) {
            revert StratRedeemSlippagesFailed();
        }

        _redeemInner(totalSupply(), slippages, 1);

        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());

        unchecked {
            for (uint256 i; i < tokenLength; ++i) {
                IERC20(tokens[i]).safeTransfer(recipient, IERC20(tokens[i]).balanceOf(address(this)));
            }
        }
    }

    function _compound(address[] calldata tokens, SwapInfo[] calldata compoundSwapInfo, uint256[] calldata slippages)
        internal
        override
        returns (int256 compoundYield)
    {
        if (compoundSwapInfo.length == 0) {
            return compoundYield;
        }

        if (slippages[0] > 1) {
            revert StratCompoundSlippagesFailed();
        }

        (address[] memory rewardTokens,) = _getProtocolRewardsInternal();

        uint256[] memory swapped = swapper.swap(rewardTokens, compoundSwapInfo, tokens, address(this));

        uint256 lpTokensBefore = _lpTokenBalance();
        _depositInner(tokens, swapped, slippages[10]);

        compoundYield = int256(YIELD_FULL_PERCENT * (_lpTokenBalance() - lpTokensBefore) / lpTokensBefore);
    }

    function _getYieldPercentage(int256 manualYield) internal view override returns (int256) {
        _verifyManualYieldPercentage(manualYield);
        return manualYield;
    }

    function _swapAssets(address[] memory, uint256[] memory, SwapInfo[] calldata) internal pure override {}

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        view
        override
        returns (uint256)
    {
        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());

        return priceFeedManager.assetToUsdCustomPriceBulk(tokens, _getTokenWorth(tokens), exchangeRates);
    }

    // specific

    function _depositInner(address[] calldata tokens, uint256[] memory amounts, uint256 slippage) private {
        // to curve base
        unchecked {
            for (uint256 i; i < tokenLength; ++i) {
                _resetAndApprove(IERC20(tokens[i]), pool(), amounts[i]);
            }
        }

        _addLiquidity(amounts, 0);

        // to curve meta
        uint256 lpTokenAmount = IERC20(_lpToken).balanceOf(address(this));
        _resetAndApprove(IERC20(_lpToken), _poolMeta, lpTokenAmount);
        _addLiquidityMeta(lpTokenAmount, 0, slippage);

        // to convex
        lpTokenAmount = IERC20(_poolMeta).balanceOf(address(this));
        _resetAndApprove(IERC20(_poolMeta), address(booster), lpTokenAmount);
        booster.deposit(pid, lpTokenAmount, true);

        if (_isViewExecution()) {
            emit Slippages(true, lpTokenAmount, "");
        }
    }

    function _redeemInner(uint256 ssts, uint256[] calldata slippages, uint256 slippageOffset) private {
        // from convex
        uint256 lpTokenAmount = crvRewards.balanceOf(address(this)) * ssts / totalSupply();
        crvRewards.withdrawAndUnwrap(lpTokenAmount, false);

        // from curve meta
        lpTokenAmount = IERC20(_poolMeta).balanceOf(address(this));
        _removeLiquidityBase(lpTokenAmount, 0);

        // from curve base
        lpTokenAmount = IERC20(_lpToken).balanceOf(address(this));
        _removeLiquidity(lpTokenAmount, slippages, slippageOffset);

        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());
        uint256[] memory bought = new uint256[](tokens.length);
        unchecked {
            for (uint256 i; i < tokens.length; ++i) {
                bought[i] = IERC20(tokens[i]).balanceOf(address(this));
            }
        }

        if (_isViewExecution()) {
            emit Slippages(false, 0, abi.encode(bought));
        }
    }

    function _getRewards() private returns (address[] memory) {
        // get CRV and extra rewards
        crvRewards.getReward(address(this), extraRewards);

        address[] memory rewardTokens;
        if (extraRewards) {
            uint256 extraRewardCount = crvRewards.extraRewardsLength();

            unchecked {
                rewardTokens = new address[](BASE_REWARD_COUNT + extraRewardCount);
                for (uint256 i; i < extraRewardCount; ++i) {
                    rewardTokens[BASE_REWARD_COUNT + i] = crvRewards.extraRewards(i);
                }
            }
        } else {
            rewardTokens = new address[](BASE_REWARD_COUNT);
        }

        rewardTokens[0] = crvRewardToken;
        rewardTokens[1] = cvxRewardToken;

        return rewardTokens;
    }

    function _lpTokenBalance() internal view returns (uint256) {
        return crvRewards.balanceOf(address(this));
    }

    function _getTokenWorth(address[] memory tokens) internal view returns (uint256[] memory) {
        // convex
        uint256 lpTokenAmount = crvRewards.balanceOf(address(this));

        // curve meta
        lpTokenAmount = _calcWithdrawBase(_oneLpToken) * lpTokenAmount / _oneLpToken;

        // curve base
        uint256 lpTokenTotalSupply = IERC20(_lpToken).totalSupply();
        uint256[] memory tokenWorth = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            tokenWorth[i] = _balances(i) * lpTokenAmount / lpTokenTotalSupply;
        }

        return tokenWorth;
    }

    function _getProtocolRewardsInternal() internal virtual override returns (address[] memory, uint256[] memory) {
        address[] memory rewardTokens = _getRewards();
        uint256[] memory balances = new uint256[](rewardTokens.length);

        unchecked {
            for (uint256 i; i < rewardTokens.length; ++i) {
                uint256 balance = IERC20(rewardTokens[i]).balanceOf(address(this));
                if (balance > 0) {
                    IERC20(rewardTokens[i]).safeTransfer(address(swapper), balance);

                    balances[i] = balance;
                }
            }
        }

        return (rewardTokens, balances);
    }

    function _noAddressZero(address addr) private pure {
        if (addr == address(0)) {
            revert ConfigurationAddressZero();
        }
    }
}
