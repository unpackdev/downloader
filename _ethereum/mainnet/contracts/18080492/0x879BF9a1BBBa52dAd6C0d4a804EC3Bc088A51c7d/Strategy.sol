// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./ERC20Upgradeable.sol";
import "./Constants.sol";
import "./IAssetGroupRegistry.sol";
import "./IMasterWallet.sol";
import "./IStrategy.sol";
import "./IStrategyRegistry.sol";
import "./CommonErrors.sol";
import "./Constants.sol";
import "./SpoolAccessControllable.sol";

/**
 * @notice Used when initial locked strategy shares are already minted and strategy usd value is zero.
 */
error StrategyWorthIsZero();

abstract contract Strategy is ERC20Upgradeable, SpoolAccessControllable, IStrategy {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IAssetGroupRegistry internal immutable _assetGroupRegistry;

    /// @notice Name of the strategy
    string private _strategyName;

    /// @dev ID of the asset group used by the strategy.
    uint256 private immutable _assetGroupId;
    /// @dev ID of the asset group used by the strategy.
    uint256 private _assetGroupIdStorage;
    // Only one of the above can be set. Use the `assetGroupId` function to read
    // the correct one.

    constructor(IAssetGroupRegistry assetGroupRegistry_, ISpoolAccessControl accessControl_, uint256 assetGroupId_)
        SpoolAccessControllable(accessControl_)
    {
        if (address(assetGroupRegistry_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        _assetGroupRegistry = assetGroupRegistry_;
        _assetGroupId = assetGroupId_;
    }

    function __Strategy_init(string memory strategyName_, uint256 assetGroupId_) internal onlyInitializing {
        if (bytes(strategyName_).length == 0) revert InvalidConfiguration();

        // asset group ID needs to be set exactly once,
        // either in constructor or initializer
        if (_assetGroupId == NULL_ASSET_GROUP_ID) {
            if (assetGroupId_ == NULL_ASSET_GROUP_ID) {
                revert InvalidAssetGroupIdInitialization();
            }
            _assetGroupIdStorage = assetGroupId_;
        } else {
            if (assetGroupId_ != NULL_ASSET_GROUP_ID) {
                revert InvalidAssetGroupIdInitialization();
            }
        }
        _assetGroupRegistry.validateAssetGroup(assetGroupId());

        _strategyName = strategyName_;

        __ERC20_init("Strategy Share Token", "SST");
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function assetGroupId() public view returns (uint256) {
        return _assetGroupId > 0 ? _assetGroupId : _assetGroupIdStorage;
    }

    function assets() public view returns (address[] memory) {
        return _assetGroupRegistry.listAssetGroup(assetGroupId());
    }

    function assetRatio() external view virtual returns (uint256[] memory);

    function strategyName() external view returns (string memory) {
        return _strategyName;
    }

    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) public virtual;

    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) public virtual;

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    function doHardWork(StrategyDhwParameterBag calldata dhwParams) external returns (DhwInfo memory dhwInfo) {
        _checkRole(ROLE_STRATEGY_REGISTRY, msg.sender);

        bool depositNeeded;
        uint256[] memory assetsToDeposit = new uint256[](dhwParams.assetGroup.length);
        unchecked {
            for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                assetsToDeposit[i] = IERC20(dhwParams.assetGroup[i]).balanceOf(address(this));

                if (assetsToDeposit[i] > 0) {
                    depositNeeded = true;
                }
            }
        }

        beforeDepositCheck(assetsToDeposit, dhwParams.slippages);
        beforeRedeemalCheck(dhwParams.withdrawnShares, dhwParams.slippages);

        // usdWorth[0]: usd worth before deposit / withdrawal
        // usdWorth[1]: usd worth after deposit / withdrawal
        uint256[2] memory usdWorth;

        // Compound and get USD value.
        {
            dhwInfo.yieldPercentage = _getYieldPercentage(dhwParams.baseYield);
            int256 compoundYield = _compound(dhwParams.assetGroup, dhwParams.compoundSwapInfo, dhwParams.slippages);
            dhwInfo.yieldPercentage += compoundYield + compoundYield * dhwInfo.yieldPercentage / YIELD_FULL_PERCENT_INT;
        }

        // collect fees, mint SVTs relative to the yield generated
        _collectPlatformFees(dhwInfo.yieldPercentage, dhwParams.platformFees);

        usdWorth[0] = _getUsdWorth(dhwParams.exchangeRates, dhwParams.priceFeedManager);

        uint256 matchedShares;
        uint256 depositShareEquivalent;
        uint256 mintedShares;
        uint256 withdrawnShares = dhwParams.withdrawnShares;

        // Calculate deposit share equivalent.
        if (depositNeeded) {
            uint256 valueToDeposit = dhwParams.priceFeedManager.assetToUsdCustomPriceBulk(
                dhwParams.assetGroup, assetsToDeposit, dhwParams.exchangeRates
            );

            if (totalSupply() < INITIAL_LOCKED_SHARES) {
                depositShareEquivalent = INITIAL_SHARE_MULTIPLIER * valueToDeposit;
            } else if (usdWorth[0] > 0) {
                depositShareEquivalent = totalSupply() * valueToDeposit / usdWorth[0];
            } else {
                revert StrategyWorthIsZero();
            }

            // Match withdrawals and deposits by taking smaller value as matched shares.
            if (depositShareEquivalent < withdrawnShares) {
                matchedShares = depositShareEquivalent;
            } else {
                matchedShares = withdrawnShares;
            }
        }

        uint256[] memory withdrawnAssets = new uint256[](dhwParams.assetGroup.length);
        bool withdrawn;
        if (depositShareEquivalent > withdrawnShares) {
            // Deposit is needed.

            // - match if needed
            if (matchedShares > 0) {
                unchecked {
                    for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                        withdrawnAssets[i] = assetsToDeposit[i] * matchedShares / depositShareEquivalent;
                        assetsToDeposit[i] -= withdrawnAssets[i];
                    }
                }
                withdrawn = true;
            }

            // - swap assets
            uint256[] memory assetsIn = new uint256[](assetsToDeposit.length);
            if (dhwParams.swapInfo.length > 0) {
                _swapAssets(dhwParams.assetGroup, assetsToDeposit, dhwParams.swapInfo);
                for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                    assetsIn[i] = assetsToDeposit[i];
                    assetsToDeposit[i] = IERC20(dhwParams.assetGroup[i]).balanceOf(address(this)) - withdrawnAssets[i];
                }
            } else {
                for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                    assetsIn[i] = assetsToDeposit[i];
                }
            }

            // - deposit assets into the protocol
            _depositToProtocol(dhwParams.assetGroup, assetsToDeposit, dhwParams.slippages);
            usdWorth[1] = _getUsdWorth(dhwParams.exchangeRates, dhwParams.priceFeedManager);

            // - mint SSTs
            mintedShares = _mintStrategyShares(usdWorth[0], usdWorth[1]);

            emit Deposited(mintedShares, usdWorth[1] - usdWorth[0], assetsIn, assetsToDeposit);

            mintedShares += matchedShares;
        } else if (withdrawnShares > depositShareEquivalent) {
            // Withdrawal is needed.

            // - match if needed
            if (matchedShares > 0) {
                unchecked {
                    withdrawnShares -= matchedShares;
                    mintedShares = matchedShares;
                }
            }

            // - redeem shares from protocol
            _redeemFromProtocol(dhwParams.assetGroup, withdrawnShares, dhwParams.slippages);
            _burn(address(this), withdrawnShares);
            withdrawn = true;

            // - figure out how much was withdrawn
            usdWorth[1] = _getUsdWorth(dhwParams.exchangeRates, dhwParams.priceFeedManager);
            unchecked {
                for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                    withdrawnAssets[i] = IERC20(dhwParams.assetGroup[i]).balanceOf(address(this));
                }
            }

            emit Withdrawn(withdrawnShares, usdWorth[1], withdrawnAssets);
        } else {
            // Neither withdrawal nor deposit is needed.

            // - match if needed
            if (matchedShares > 0) {
                mintedShares = withdrawnShares;
                unchecked {
                    for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                        withdrawnAssets[i] = assetsToDeposit[i];
                    }
                }
                withdrawn = true;
            }

            usdWorth[1] = usdWorth[0];
        }

        // Transfer withdrawn assets to master wallet if needed.
        if (withdrawn) {
            unchecked {
                for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                    IERC20(dhwParams.assetGroup[i]).safeTransfer(dhwParams.masterWallet, withdrawnAssets[i]);
                }
            }
        }

        dhwInfo.sharesMinted = mintedShares;
        dhwInfo.assetsWithdrawn = withdrawnAssets;
        dhwInfo.valueAtDhw = usdWorth[1];
        dhwInfo.totalSstsAtDhw = totalSupply();
    }

    function redeemFast(
        uint256 shares,
        address masterWallet,
        address[] calldata assetGroup,
        uint256[] calldata slippages
    ) external returns (uint256[] memory) {
        if (
            !_accessControl.hasRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
                && !_accessControl.hasRole(ROLE_STRATEGY_REGISTRY, msg.sender)
        ) {
            revert NotFastRedeemer(msg.sender);
        }

        return _redeemShares(shares, address(this), masterWallet, assetGroup, slippages);
    }

    function redeemShares(uint256 shares, address redeemer, address[] calldata assetGroup, uint256[] calldata slippages)
        external
        returns (uint256[] memory)
    {
        _checkRole(ROLE_STRATEGY_REGISTRY, msg.sender);

        return _redeemShares(shares, redeemer, redeemer, assetGroup, slippages);
    }

    /// @dev is only called when reallocating
    function depositFast(
        address[] calldata assetGroup,
        uint256[] calldata exchangeRates,
        IUsdPriceFeedManager priceFeedManager,
        uint256[] calldata slippages,
        SwapInfo[] calldata swapInfo
    ) external onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender) returns (uint256) {
        // get amount of assets available to deposit
        uint256[] memory assetsToDeposit = new uint256[](assetGroup.length);
        for (uint256 i; i < assetGroup.length; ++i) {
            assetsToDeposit[i] = IERC20(assetGroup[i]).balanceOf(address(this));
        }

        // swap assets
        _swapAssets(assetGroup, assetsToDeposit, swapInfo);
        for (uint256 i; i < assetGroup.length; ++i) {
            assetsToDeposit[i] = IERC20(assetGroup[i]).balanceOf(address(this));
        }

        // deposit assets
        uint256 usdWorth0 = _getUsdWorth(exchangeRates, priceFeedManager);
        _depositToProtocol(assetGroup, assetsToDeposit, slippages);
        uint256 usdWorth1 = _getUsdWorth(exchangeRates, priceFeedManager);

        // mint SSTs
        uint256 sstsToMint = _mintStrategyShares(usdWorth0, usdWorth1);

        return sstsToMint;
    }

    function claimShares(address smartVault, uint256 amount) external onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender) {
        _transfer(address(this), smartVault, amount);
    }

    function releaseShares(address smartVault, uint256 amount)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
    {
        _transfer(smartVault, address(this), amount);
    }

    function emergencyWithdraw(uint256[] calldata slippages, address recipient)
        external
        onlyRole(ROLE_STRATEGY_REGISTRY, msg.sender)
    {
        _emergencyWithdrawImpl(slippages, recipient);
    }

    function getProtocolRewards() external onlyViewExecution returns (address[] memory, uint256[] memory) {
        return _getProtocolRewardsInternal();
    }

    function getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
        returns (uint256)
    {
        return _getUsdWorth(exchangeRates, priceFeedManager);
    }

    /* ========== PRIVATE/INTERNAL FUNCTIONS ========== */

    function _mintStrategyShares(uint256 usdWorthBefore, uint256 usdWorthAfter)
        private
        returns (uint256 mintedShares)
    {
        uint256 totalSupply_ = totalSupply();

        if (totalSupply_ < INITIAL_LOCKED_SHARES) {
            // multiply with usd worth after deposit as there are no other owned shares
            mintedShares = usdWorthAfter * INITIAL_SHARE_MULTIPLIER;

            unchecked {
                uint256 lockedSharesLeftToMint = INITIAL_LOCKED_SHARES - totalSupply_;

                if (mintedShares < lockedSharesLeftToMint) {
                    lockedSharesLeftToMint = mintedShares;
                }

                mintedShares -= lockedSharesLeftToMint;

                _mint(INITIAL_LOCKED_SHARES_ADDRESS, lockedSharesLeftToMint);
            }
        } else if (usdWorthBefore > 0) {
            mintedShares = (usdWorthAfter - usdWorthBefore) * totalSupply_ / usdWorthBefore;
        } else {
            revert StrategyWorthIsZero();
        }

        _mint(address(this), mintedShares);
    }

    function _redeemShares(
        uint256 shares,
        address shareOwner,
        address recipient,
        address[] calldata assetGroup,
        uint256[] calldata slippages
    ) internal virtual returns (uint256[] memory) {
        // redeem shares from protocol
        uint256[] memory assetsWithdrawn = _redeemFromProtocolAndReturnAssets(assetGroup, shares, slippages);
        _burn(shareOwner, shares);

        // transfer assets to recipient (master wallet in case of redeemFast)
        unchecked {
            for (uint256 i; i < assetGroup.length; ++i) {
                IERC20(assetGroup[i]).safeTransfer(recipient, assetsWithdrawn[i]);
            }
        }

        return assetsWithdrawn;
    }

    /**
     * @notice Calculate and mint platform performance fees based on the yield generated.
     * @param yieldPct Yield generated since previous DHW. Full percent is `YIELD_FULL_PERCENT`.
     * @param platformFees Platform fees info, containing information of the sice and recipient of the fees (SSTs).
     * @return sharesMinted Returns newly minted shares representing the platform performance fees.
     */
    function _collectPlatformFees(int256 yieldPct, PlatformFees calldata platformFees)
        internal
        virtual
        returns (uint256 sharesMinted)
    {
        if (yieldPct > 0) {
            uint256 uint256YieldPct = uint256(yieldPct);

            uint256 yieldPctUsersPlusOne = uint256YieldPct
                * (FULL_PERCENT - platformFees.ecosystemFeePct - platformFees.treasuryFeePct)
                + FULL_PERCENT * YIELD_FULL_PERCENT;
            uint256 totalSupplyTimesYieldPct = totalSupply() * uint256YieldPct;

            // mint new ecosystem fee SSTs
            uint256 newEcosystemFeeSsts = totalSupplyTimesYieldPct * platformFees.ecosystemFeePct / yieldPctUsersPlusOne;
            _mint(platformFees.ecosystemFeeReceiver, newEcosystemFeeSsts);

            // mint new treasury fee SSTs
            uint256 newTreasuryFeeSsts = totalSupplyTimesYieldPct * platformFees.treasuryFeePct / yieldPctUsersPlusOne;
            _mint(platformFees.treasuryFeeReceiver, newTreasuryFeeSsts);

            unchecked {
                sharesMinted = newEcosystemFeeSsts + newTreasuryFeeSsts;
            }

            emit PlatformFeesCollected(address(this), sharesMinted);
        }
    }

    function _redeemFromProtocolAndReturnAssets(address[] calldata tokens, uint256 ssts, uint256[] calldata slippages)
        internal
        virtual
        returns (uint256[] memory withdrawnAssets)
    {
        withdrawnAssets = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            withdrawnAssets[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        _redeemFromProtocol(tokens, ssts, slippages);

        for (uint256 i; i < tokens.length; ++i) {
            withdrawnAssets[i] = IERC20(tokens[i]).balanceOf(address(this)) - withdrawnAssets[i];
        }
    }

    function _calculateYieldPercentage(uint256 previousValue, uint256 currentValue)
        internal
        pure
        returns (int256 yieldPercentage)
    {
        if (currentValue > previousValue) {
            yieldPercentage = int256((currentValue - previousValue) * YIELD_FULL_PERCENT / previousValue);
        } else if (previousValue > currentValue) {
            yieldPercentage = -int256((previousValue - currentValue) * YIELD_FULL_PERCENT / previousValue);
        }
    }

    function _resetAndApprove(IERC20 token, address spender, uint256 amount) internal {
        _resetAllowance(token, spender);
        token.safeApprove(spender, amount);
    }

    function _resetAllowance(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
    }

    function _isViewExecution() internal view returns (bool) {
        return tx.origin == address(0);
    }

    function _compound(address[] calldata tokens, SwapInfo[] calldata compoundSwapInfo, uint256[] calldata slippages)
        internal
        virtual
        returns (int256 compoundYield);

    function _getYieldPercentage(int256 manualYield) internal virtual returns (int256);

    /**
     * @dev Swaps assets.
     * @param tokens Addresses of tokens to swap.
     * @param toSwap Available amounts to swap.
     * @param swapInfo Information on how to swap.
     */
    function _swapAssets(address[] memory tokens, uint256[] memory toSwap, SwapInfo[] calldata swapInfo)
        internal
        virtual;

    /**
     * @dev Deposits assets into the underlying protocol.
     * @param tokens Addresses of asset tokens.
     * @param amounts Amounts to deposit.
     * @param slippages Slippages to guard depositing.
     */
    function _depositToProtocol(address[] calldata tokens, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        virtual;

    /**
     * @dev Redeems shares from the undelying protocol.
     * @param tokens Addresses of asset tokens.
     * @param ssts Amount of strategy tokens to redeem.
     * @param slippages Slippages to guard redeemal.
     */
    function _redeemFromProtocol(address[] calldata tokens, uint256 ssts, uint256[] calldata slippages)
        internal
        virtual;

    function _emergencyWithdrawImpl(uint256[] calldata slippages, address recipient) internal virtual;

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        virtual
        returns (uint256);

    /**
     * @dev Gets protocol rewards.
     * @return tokens Addresses of reward tokens.
     * @return amounts Amount of each reward token.
     */
    function _getProtocolRewardsInternal()
        internal
        virtual
        returns (address[] memory tokens, uint256[] memory amounts);

    /* ========== MODIFIERS ========== */

    modifier onlyViewExecution() {
        require(_isViewExecution());
        _;
    }
}
