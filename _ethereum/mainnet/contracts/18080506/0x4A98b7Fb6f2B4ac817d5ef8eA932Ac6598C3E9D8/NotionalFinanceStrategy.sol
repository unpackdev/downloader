// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./Math.sol";
import "./INotional.sol";
import "./INToken.sol";
import "./AssetRateAdapter.sol";
import "./ISwapper.sol";
import "./Strategy.sol";

contract NotionalFinanceStrategy is Strategy {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    uint256 private constant NTOKEN_DECIMALS_MULTIPLIER = 10 ** 8;

    uint256 private constant EXCHANGE_RATE_MULTIPLIER = 10 ** 30;

    /* ========== STATE VARIABLES ========== */

    /// @notice Swapper contract
    ISwapper public immutable swapper;

    /// @notice Notional proxy contract
    INotional public immutable notional;

    /// @notice NOTE token
    /// @dev Reward token when participating in the Notional Finance protocol.
    IERC20 public immutable note;

    /// @notice nToken for this underlying
    INToken public nToken;

    /// @notice underlying token ID in notional contract
    uint16 private _id;

    uint80 private _underlyingDecimalsMultiplier;

    /// @notice exchangeRateCurrent at the last DHW.
    uint256 private _lastExchangeRate;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        ISwapper swapper_,
        INotional notional_,
        IERC20 note_
    ) Strategy(assetGroupRegistry_, accessControl_, NULL_ASSET_GROUP_ID) {
        if (address(swapper_) == address(0)) revert ConfigurationAddressZero();
        if (address(notional_) == address(0)) revert ConfigurationAddressZero();
        if (address(note_) == address(0)) revert ConfigurationAddressZero();

        swapper = swapper_;
        notional = notional_;
        note = note_;
    }

    function initialize(string memory strategyName_, uint256 assetGroupId_, INToken nToken_) external initializer {
        __Strategy_init(strategyName_, assetGroupId_);

        if (address(nToken_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        address[] memory tokens = assets();
        (, Token memory underlyingToken) = notional.getCurrency(nToken_.currencyId());

        if (tokens.length != 1 || tokens[0] != underlyingToken.tokenAddress) {
            revert InvalidAssetGroup(assetGroupId_);
        }

        nToken = nToken_;
        _id = nToken_.currencyId();

        _underlyingDecimalsMultiplier = SafeCast.toUint80(10 ** IERC20Metadata(tokens[0]).decimals());

        _lastExchangeRate =
            uint256(nToken.getPresentValueUnderlyingDenominated()) * EXCHANGE_RATE_MULTIPLIER / nToken.totalSupply();
    }

    function assetRatio() external pure override returns (uint256[] memory) {
        uint256[] memory _assetRatio = new uint256[](1);
        _assetRatio[0] = 1;
        return _assetRatio;
    }

    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts) {
        uint256 nTokenBalance = nToken.balanceOf(address(this));

        amounts = new uint256[](1);
        amounts[0] = _getNTokenValue(nTokenBalance);
    }

    /**
     * @notice Nothing to swap as it's only one asset.
     */
    function _swapAssets(address[] memory, uint256[] memory, SwapInfo[] calldata) internal override {}

    function _compound(address[] calldata tokens, SwapInfo[] calldata swapInfo, uint256[] calldata)
        internal
        override
        returns (int256 compoundedYieldPercentage)
    {
        if (swapInfo.length > 0) {
            uint256 noteBalance = _getNotionalFinanceReward();

            if (noteBalance > 0) {
                note.safeTransfer(address(swapper), noteBalance);
                address[] memory tokensIn = new address[](1);
                tokensIn[0] = address(note);
                uint256 swappedAmount = swapper.swap(tokensIn, swapInfo, tokens, address(this))[0];

                if (swappedAmount > 0) {
                    uint256 nTokenBalanceBefore = nToken.balanceOf(address(this));
                    _depositToNotionalProtocol(IERC20(tokens[0]), swappedAmount);

                    compoundedYieldPercentage =
                        _calculateYieldPercentage(nTokenBalanceBefore, nToken.balanceOf(address(this)));
                }
            }
        }
    }

    function _getYieldPercentage(int256) internal override returns (int256 baseYieldPercentage) {
        uint256 exchangeRateCurrent =
            uint256(nToken.getPresentValueUnderlyingDenominated()) * EXCHANGE_RATE_MULTIPLIER / nToken.totalSupply();

        baseYieldPercentage = _calculateYieldPercentage(_lastExchangeRate, exchangeRateCurrent);

        _lastExchangeRate = exchangeRateCurrent;
    }

    function _depositToProtocol(address[] calldata tokens, uint256[] memory amounts, uint256[] calldata)
        internal
        override
    {
        _depositToNotionalProtocol(IERC20(tokens[0]), amounts[0]);
    }

    function _depositToNotionalProtocol(IERC20 token, uint256 amount) private {
        if (amount > 0) {
            _resetAndApprove(token, address(notional), amount);

            BalanceAction[] memory actions =
                _buildBalanceAction(DepositActionType.DepositUnderlyingAndMintNToken, amount, false, false);

            notional.batchBalanceAction(address(this), actions);
        }
    }

    /**
     * @notice Withdraw lp tokens from the Compound market
     */
    function _redeemFromProtocol(address[] calldata, uint256 ssts, uint256[] calldata) internal override {
        if (ssts == 0) {
            return;
        }

        uint256 nTokenWithdrawAmount = (nToken.balanceOf(address(this)) * ssts) / totalSupply();

        _withdrawFromNotionalProtocol(nTokenWithdrawAmount);
    }

    function _emergencyWithdrawImpl(uint256[] calldata, address recipient) internal override {
        _withdrawFromNotionalProtocol(nToken.balanceOf(address(this)));

        address[] memory tokens = assets();
        IERC20(tokens[0]).safeTransfer(recipient, IERC20(tokens[0]).balanceOf(address(this)));
    }

    function _withdrawFromNotionalProtocol(uint256 nTokenWithdrawAmount) private {
        if (nTokenWithdrawAmount > 0) {
            BalanceAction[] memory actions =
                _buildBalanceAction(DepositActionType.RedeemNToken, nTokenWithdrawAmount, true, true);

            notional.batchBalanceAction(address(this), actions);
        }
    }

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        view
        override
        returns (uint256 usdValue)
    {
        uint256 nTokenBalance = nToken.balanceOf(address(this));
        if (nTokenBalance > 0) {
            uint256 tokenValue = _getNTokenValue(nTokenBalance);

            address[] memory assetGroup = _assetGroupRegistry.listAssetGroup(assetGroupId());
            usdValue = priceFeedManager.assetToUsdCustomPrice(assetGroup[0], tokenValue, exchangeRates[0]);
        }
    }

    /**
     * @dev Get value of the nTkoen amount in the asset token amount
     * @param nTokenAmount nToken amount
     * @return tokenAmount value of `nTokenAmount` in asset tokens
     */
    function _getNTokenValue(uint256 nTokenAmount) private view returns (uint256) {
        if (nTokenAmount == 0) return 0;
        return (nTokenAmount * uint256(nToken.getPresentValueUnderlyingDenominated()) * _underlyingDecimalsMultiplier)
            / nToken.totalSupply() / NTOKEN_DECIMALS_MULTIPLIER;
    }

    function _buildBalanceAction(
        DepositActionType actionType,
        uint256 depositActionAmount,
        bool withdrawEntireCashBalance,
        bool redeemToUnderlying
    ) private view returns (BalanceAction[] memory actions) {
        actions = new BalanceAction[](1);
        actions[0] = BalanceAction({
            actionType: actionType,
            currencyId: _id,
            depositActionAmount: depositActionAmount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: withdrawEntireCashBalance,
            redeemToUnderlying: redeemToUnderlying
        });
    }

    function beforeDepositCheck(uint256[] memory, uint256[] calldata) public view override {}

    function beforeRedeemalCheck(uint256, uint256[] calldata) public view override {}

    function _getProtocolRewardsInternal() internal virtual override returns (address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(note);
        amounts[0] = _getNotionalFinanceReward();

        return (tokens, amounts);
    }

    function _getNotionalFinanceReward() internal returns (uint256) {
        notional.nTokenClaimIncentives();

        return note.balanceOf(address(this));
    }
}
