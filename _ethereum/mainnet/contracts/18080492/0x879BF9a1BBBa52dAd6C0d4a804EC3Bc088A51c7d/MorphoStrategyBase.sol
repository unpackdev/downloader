// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IMorpho.sol";
import "./ISwapper.sol";
import "./Strategy.sol";
import "./StrategyManualYieldVerifier.sol";

abstract contract MorphoStrategyBase is StrategyManualYieldVerifier, Strategy {
    using SafeERC20 for IERC20;

    /// @notice Swapper implementation.
    ISwapper public immutable swapper;

    /// @notice Morpho implementation.
    IMorpho public immutable morpho;

    /// @notice Reward token when participating in the underlying protocol Morpho deposits into.
    IERC20 public immutable poolRewardToken;

    /// @notice Token of the underlying protocol (e.g., cToken, aToken)
    address public poolTokenAddress;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        IMorpho morpho_,
        IERC20 poolRewardToken_,
        ISwapper swapper_
    ) Strategy(assetGroupRegistry_, accessControl_, NULL_ASSET_GROUP_ID) {
        if (address(swapper_) == address(0)) revert ConfigurationAddressZero();
        if (address(morpho_) == address(0)) revert ConfigurationAddressZero();
        if (address(poolRewardToken_) == address(0)) revert ConfigurationAddressZero();

        swapper = swapper_;
        morpho = morpho_;
        poolRewardToken = poolRewardToken_;
    }

    function __MorphoStrategyBase_init(
        string memory strategyName_,
        uint256 assetGroupId_,
        address poolTokenAddress_,
        int128 positiveYieldLimit_,
        int128 negativeYieldLimit_
    ) internal onlyInitializing {
        __Strategy_init(strategyName_, assetGroupId_);

        if (poolTokenAddress_ == address(0)) revert ConfigurationAddressZero();

        poolTokenAddress = poolTokenAddress_;

        _setPositiveYieldLimit(positiveYieldLimit_);
        _setNegativeYieldLimit(negativeYieldLimit_);
    }

    function assetRatio() external pure override returns (uint256[] memory) {
        uint256[] memory _assetRatio = new uint256[](1);
        _assetRatio[0] = 1;
        return _assetRatio;
    }

    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts) {
        amounts = new uint256[](1);
        amounts[0] = _getTotalBalance();
    }

    /**
     * @notice Nothing to swap as it's only one asset.
     */
    function _swapAssets(address[] memory, uint256[] memory, SwapInfo[] calldata) internal override {}

    function _compound(address[] calldata tokens, SwapInfo[] calldata swapInfo, uint256[] calldata)
        internal
        virtual
        override
        returns (int256 compoundedYieldPercentage)
    {
        if (swapInfo.length > 0) {
            uint256 compBalance = _getMorphoReward();

            if (compBalance > 0) {
                poolRewardToken.safeTransfer(address(swapper), compBalance);
                address[] memory tokensIn = new address[](1);
                tokensIn[0] = address(poolRewardToken);
                uint256 swappedAmount = swapper.swap(tokensIn, swapInfo, tokens, address(this))[0];

                if (swappedAmount > 0) {
                    uint256 balanceBefore = _getTotalBalance();

                    _depositToMorphoProtocol(IERC20(tokens[0]), swappedAmount);

                    compoundedYieldPercentage = _calculateYieldPercentage(balanceBefore, balanceBefore + swappedAmount);
                }
            }
        }
    }

    function _getYieldPercentage(int256 manualYield) internal view virtual override returns (int256) {
        _verifyManualYieldPercentage(manualYield);
        return manualYield;
    }

    function _depositToProtocol(address[] calldata tokens, uint256[] memory amounts, uint256[] calldata)
        internal
        override
    {
        _depositToMorphoProtocol(IERC20(tokens[0]), amounts[0]);
    }

    function _depositToMorphoProtocol(IERC20 token, uint256 amount) private {
        if (amount > 0) {
            _resetAndApprove(token, address(morpho), amount);

            morpho.supply(poolTokenAddress, address(this), amount);
        }
    }

    function _redeemFromProtocol(address[] calldata, uint256 ssts, uint256[] calldata) internal override {
        if (ssts == 0) {
            return;
        }

        uint256 withdrawAmount = (_getTotalBalance() * ssts) / totalSupply();

        if (withdrawAmount > 0) {
            morpho.withdraw(poolTokenAddress, withdrawAmount);
        }
    }

    function _emergencyWithdrawImpl(uint256[] calldata, address recipient) internal override {
        morpho.withdraw(poolTokenAddress, type(uint256).max);

        address[] memory tokens = assets();
        IERC20(tokens[0]).safeTransfer(recipient, IERC20(tokens[0]).balanceOf(address(this)));
    }

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        view
        override
        returns (uint256 usdValue)
    {
        uint256 assetBalance = _getTotalBalance();
        if (assetBalance > 0) {
            address[] memory assetGroup = _assetGroupRegistry.listAssetGroup(assetGroupId());
            usdValue = priceFeedManager.assetToUsdCustomPrice(assetGroup[0], assetBalance, exchangeRates[0]);
        }
    }

    function beforeDepositCheck(uint256[] memory, uint256[] calldata) public view override {}

    function beforeRedeemalCheck(uint256, uint256[] calldata) public view override {}

    function _getTotalBalance() internal view virtual returns (uint256);

    function _getProtocolRewardsInternal() internal virtual override returns (address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(poolRewardToken);
        amounts[0] = _getMorphoReward();

        return (tokens, amounts);
    }

    function _getMorphoReward() internal returns (uint256) {
        address[] memory cTokens = new address[](1);
        cTokens[0] = poolTokenAddress;
        morpho.claimRewards(cTokens, false);

        return poolRewardToken.balanceOf(address(this));
    }
}
