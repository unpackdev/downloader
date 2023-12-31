// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./MathUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./DefinitiveConstants.sol";
import "./DefinitiveAssets.sol";
import "./ILLSDStrategyV1.sol";
import "./IBaseTransfersV1.sol";
import "./IBaseSafeHarborMode.sol";
import "./CoreSignatureVerification.sol";
import "./IERC20Metadata.sol";
import "./IMultiUserLLSDStrategy.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./DefinitiveErrors.sol";

import "./BaseMultiUserStrategyV1.sol";

interface ILLSDStrategy is ILLSDStrategyV1, IBaseTransfersV1, IBaseSafeHarborMode {
    function DEFAULT_ADMIN_ROLE() external returns (bytes32);
}

/// @notice Uses selected methods from ERC4626
contract MultiUserLLSDStrategy is BaseMultiUserStrategyV1, IMultiUserLLSDStrategy, CoreSignatureVerification {
    using MathUpgradeable for uint256;
    using DefinitiveAssets for IERC20;

    IERC20Upgradeable private ASSET;
    uint8 private ASSET_DECIMALS;

    /// @notice Initializes the safe LTV range to ± 5% in basis points (1e4 precision)
    /// @notice Enforces an increase/decrease in LTV per transaction
    /// @dev If LTV is 70%, a value of `500` will enforce ±5% of the existing LTV (73.5% <= New LTV >= 66.5%)
    /// @dev **NOT** ± 500bps of the existing LTV: (75% <= New LTV >= 65%)
    uint256 internal SAFE_LTV_THRESHOLD;

    /// @notice Value of threshold allowed when comparing the initial vs final ratio of `totalAssets`:`totalSupply`
    /// @notice when minting or burning shares.
    /// @dev Examples for an initial ratio of 1e18:
    /// @dev 1e4: (more strict) ratio after operation must equal 1e18 ± 1e4
    /// @dev 1e8: (less strict) ratio after operation must equal 1e18 ± 1e8
    uint256 internal SHARES_TO_ASSETS_RATIO_THRESHOLD;

    // transfers throttling
    uint256 internal _transfersThisBlock;
    uint256 internal _latestTransfersBlockNumber;
    uint256 internal MAX_TRANSFERS_PER_BLOCK;

    /// @notice Defines the ABI version of MultiUserLPStakingStrategy
    uint256 public constant ABI_VERSION = 1;

    event MaxTransfersPerBlockUpdate(uint256 maxTransfers);

    modifier enforceValidations(uint256 deadline) {
        // Enforce deadline validation prior to method execution
        _enforceDeadline(deadline);

        (uint256 initialAssets, uint256 initialSupply, uint256 initialLTV) = (
            totalAssets(),
            totalSupply(),
            ILLSDStrategy(VAULT).getLTV()
        );

        _;

        _validateSafeLTVThreshold(initialAssets, initialSupply, initialLTV);
        _validateSharesToAssetRatio(initialAssets, initialSupply);
    }

    /// @notice Constructor on the implementation contract should call _disableInitializers()
    /// @dev https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/2
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev ALWAYS INCLUDE VAULT: To maintain MU_* and Vault relationship during upgrades
    function initialize(
        address payable _vault,
        address __asset,
        string memory _name,
        string memory _symbol,
        address _wrappedNativeAssetAddress,
        address _strategyAdmin,
        address _sigVerificationSigner,
        address _feeAccount
    ) public initializer {
        if (ILLSDStrategy(_vault).STAKING_TOKEN() != __asset) {
            revert InvalidInputs();
        }

        __BaseMultiUserStrategy_init(_vault, _name, _symbol, _feeAccount);
        __CoreSignatureVerification_init(_sigVerificationSigner);
        __CoreTransfersNative_init();
        __BaseNativeWrapper_init(_wrappedNativeAssetAddress);

        IERC20Upgradeable mAsset = IERC20Upgradeable(__asset);
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(mAsset);
        ASSET_DECIMALS = success ? assetDecimals : 18;
        ASSET = mAsset;
        SAFE_LTV_THRESHOLD = 500;
        SHARES_TO_ASSETS_RATIO_THRESHOLD = 1e12;
        MAX_TRANSFERS_PER_BLOCK = 1;
        _transferOwnership(_strategyAdmin);
    }

    function _enforceTransferLimits() private {
        if (block.number != _latestTransfersBlockNumber) {
            _latestTransfersBlockNumber = block.number;
            delete _transfersThisBlock;
        }
        _transfersThisBlock += 1;
        if (_transfersThisBlock > MAX_TRANSFERS_PER_BLOCK) {
            revert TransfersLimitExceeded();
        }
    }

    /// @dev Ratio Precision: 1e18
    /// @dev Calculation Precision: 1e36 (or 1e18 ** 2)
    function _getSharesToAssetsRatio(uint256 _totalSupply, uint256 _totalAssets) internal pure returns (uint256 ratio) {
        if (_totalSupply > 0) {
            ratio = _totalAssets.mulDiv(1e36, _totalSupply * 1e18);
        }
    }

    function setSharesToAssetRatioThreshold(uint256 threshold) external onlyDefinitiveVaultAdmins {
        SHARES_TO_ASSETS_RATIO_THRESHOLD = threshold;
        emit UpdateSharesToAssetsRatioThreshold(_msgSender(), threshold);
    }

    function setSafeLTVThreshold(uint256 threshold) external onlyDefinitiveVaultAdmins {
        if (threshold > 10_000 || threshold == 0) {
            revert InvalidInputs();
        }

        SAFE_LTV_THRESHOLD = threshold;
        emit UpdateSafeLTVThreshold(_msgSender(), threshold);
    }

    function setMaxTransfersPerBlock(uint256 maxTransfers) external onlyDefinitiveVaultAdmins {
        MAX_TRANSFERS_PER_BLOCK = maxTransfers;
        emit MaxTransfersPerBlockUpdate(maxTransfers);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20MetadataUpgradeable, ERC20Upgradeable) returns (uint8) {
        return ASSET_DECIMALS + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(ASSET);
    }

    /// @notice Shows total assets of the underlying vault in terms of the underlying vault's debt asset
    function totalAssets() public view override returns (uint256 totalAssetsAmount) {
        address mVAULT = (VAULT);
        address mSTAKED_TOKEN = ILLSDStrategy(VAULT).STAKED_TOKEN();
        address mSTAKING_TOKEN = ILLSDStrategy(VAULT).STAKING_TOKEN();
        uint256 collateralAmount = ILLSDStrategy(VAULT).getCollateralAmount();
        uint256 debtAmount = ILLSDStrategy(VAULT).getDebtAmount();
        uint256 dryCollateral = IERC20(mSTAKED_TOKEN).balanceOf(mVAULT);
        uint256 dryDebt = IERC20(mSTAKING_TOKEN).balanceOf(mVAULT);
        (uint256 collateralToDebtPriceRatio, uint256 collateralToDebtPriceRatioPrecision) = ILLSDStrategy(VAULT)
            .getCollateralToDebtPrice();

        // Add dry collateral in terms of debt
        totalAssetsAmount += dryCollateral.mulDiv(collateralToDebtPriceRatioPrecision, collateralToDebtPriceRatio);

        // Add dry debt
        totalAssetsAmount += dryDebt;

        // If collateral is 0, debt must be 0
        if (collateralAmount > 0) {
            // Add supplied collateral in terms of debt
            totalAssetsAmount += collateralAmount.mulDiv(
                collateralToDebtPriceRatioPrecision,
                collateralToDebtPriceRatio
            );

            // Subtract debt
            totalAssetsAmount -= debtAmount;
        }
    }

    /// @notice External method to preview deposit of this contract's underlying deposit
    /// @dev Should not be used for internal calculations.  See `_getSharesFromDepositedAmount`
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return assets.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), MathUpgradeable.Rounding.Down);
    }

    function encodeDepositParams(DepositParams calldata depositParams) public pure returns (bytes32) {
        return keccak256(abi.encode(depositParams));
    }

    function encodeRedeemParams(RedeemParams calldata redeemParams) public pure returns (bytes32) {
        return keccak256(abi.encode(redeemParams));
    }

    function deposit(
        address receiver,
        DepositParams calldata depositParams,
        bytes calldata depositParamsSignature
    )
        external
        payable
        revertIfSafeHarborModeEnabled
        enforceValidations(depositParams.deadline)
        nonReentrant
        returns (uint256 shares, uint256 assetsAdded)
    {
        _enforceTransferLimits();
        _verifySignature(encodeDepositParams(depositParams), depositParamsSignature);

        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.

        // Handle deposited assets
        _depositNativeAndERC20(depositParams.depositTokens);

        // Wrap native asset (if necessary)
        DefinitiveConstants.Assets memory depositTokens = _wrapDepositedNativeAsset(depositParams.depositTokens);

        uint256 initialTotalAssets = totalAssets();

        _approveAssetsForDeposit(depositTokens);

        ILLSDStrategy(VAULT).deposit(depositTokens.amounts, depositTokens.addresses);

        ILLSDStrategy(VAULT).enter(
            depositParams.enterCtx.flashloanAmount,
            depositParams.enterCtx.swapPayload,
            depositParams.enterCtx.maxLTV
        );

        ILLSDStrategy(VAULT).sweepDust();

        // `assetsAdded` is the amount of value provided to the underlying LLSDStrategy
        // The depositor pays for fees/slippage associated with entering the vault
        assetsAdded = totalAssets() - initialTotalAssets;

        shares = _getSharesFromDepositedAmount(assetsAdded);

        _mint(receiver, shares);

        emit Mint(IMultiUserLLSDStrategy.MintEventData(_msgSender(), receiver, depositTokens, assetsAdded, shares));
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }

    // Asset and AssetAmount are provided by the consumer
    // Contract calculates the shares based on the net effect to the underlying vault
    // The owner must have the allowance/shares to afford the decrease in value of the underlying vault
    function redeem(
        address receiver,
        address _owner,
        RedeemParams calldata redeemParams,
        bytes calldata redeemParamsSignature
    )
        external
        revertIfSafeHarborModeEnabled
        enforceValidations(redeemParams.deadline)
        nonReentrant
        returns (DefinitiveConstants.Assets memory tokensRemoved)
    {
        _enforceTransferLimits();
        _verifySignature(encodeRedeemParams(redeemParams), redeemParamsSignature);

        tokensRemoved = _getVaultDryBalances();

        uint256 assetsRemoved = totalAssets();

        ILLSDStrategy(VAULT).exit(
            redeemParams.exitCtx.flashloanAmount,
            redeemParams.exitCtx.repayAmount,
            redeemParams.exitCtx.decollateralizeAmount,
            redeemParams.exitCtx.swapPayload,
            redeemParams.exitCtx.maxLTV
        );

        {
            uint256 i = 0;
            while (i < tokensRemoved.addresses.length) {
                // Withdrawal amount is the increase in dry balance
                // If there's no increase, then the withdrawal amount is 0
                uint256 balanceAfter = IERC20(tokensRemoved.addresses[i]).balanceOf((VAULT));
                if (balanceAfter > tokensRemoved.amounts[i]) {
                    tokensRemoved.amounts[i] = balanceAfter - tokensRemoved.amounts[i];
                } else {
                    tokensRemoved.amounts[i] = 0;
                }

                unchecked {
                    ++i;
                }
            }
        }

        // Handle fees
        uint256 redeemSharesTotal = redeemParams.sharesBurned +
            redeemParams.sharesFees +
            redeemParams.sharesFeesAdditional;
        if (_msgSender() != _owner) {
            _spendAllowance(_owner, _msgSender(), redeemSharesTotal);
        }
        uint256 sharesFeesTotal = redeemSharesTotal - redeemParams.sharesBurned;
        if (sharesFeesTotal > 0) {
            // transfer fee shares
            _transferShares(_owner, getFeesAccount(), sharesFeesTotal);
            emit RedemptionFee(
                _msgSender(),
                address(this),
                redeemSharesTotal,
                redeemParams.sharesFees,
                redeemParams.sharesFeesAdditional
            );
        }

        _burn(_owner, redeemParams.sharesBurned);

        _withdrawAndTransfer(receiver, tokensRemoved);

        // `assetsRemoved` is the amount of value withdrawn from the underlying LLSDStrategy
        // The depositor pays for fees/slippage associated with exiting the vault
        assetsRemoved = assetsRemoved - totalAssets();

        emit Redeem(
            IMultiUserLLSDStrategy.RedeemEventData(
                _msgSender(),
                receiver,
                _owner,
                tokensRemoved,
                assetsRemoved,
                redeemSharesTotal
            )
        );
    }

    function _getVaultDryBalances() private view returns (DefinitiveConstants.Assets memory tokensRemoved) {
        (tokensRemoved.amounts, tokensRemoved.addresses) = (new uint256[](2), new address[](2));

        tokensRemoved.addresses[0] = ILLSDStrategy(VAULT).STAKED_TOKEN();
        tokensRemoved.addresses[1] = ILLSDStrategy(VAULT).STAKING_TOKEN();

        uint256 i;

        {
            // Initialize `tokensRemoved` array to the vault's dry balances
            i = 0;
            uint256 length = tokensRemoved.addresses.length;
            while (i < length) {
                tokensRemoved.amounts[i] = IERC20(tokensRemoved.addresses[i]).balanceOf((VAULT));
                unchecked {
                    ++i;
                }
            }
        }
    }

    function _getSharesFromDepositedAmount(uint256 assets) internal view returns (uint256) {
        uint256 _totalAssets = totalAssets();
        uint256 totalAssetsBeforeDeposit = _totalAssets > assets ? _totalAssets - assets : 0;
        return
            assets.mulDiv(
                totalSupply() + 10 ** _decimalsOffset(),
                totalAssetsBeforeDeposit + 1,
                MathUpgradeable.Rounding.Down
            );
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20Upgradeable asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    function _validateSafeLTVThreshold(
        uint256 initialTotalAssets,
        uint256 initialTotalSupply,
        uint256 initialLTV
    ) private view {
        (uint256 mSAFE_LTV_THRESHOLD, uint256 totalAssetsAfter, uint256 totalSupplyAfter, uint256 ltvAfter) = (
            SAFE_LTV_THRESHOLD,
            totalAssets(),
            totalSupply(),
            ILLSDStrategy(VAULT).getLTV()
        );

        {
            // Ignore if the vault is minting initial shares
            bool isMintingInitialShares = initialTotalAssets == 0 && initialTotalSupply == 0;

            // Ignore if the vault is burning all outstanding shares
            bool isBurningAllOutstandingShares = totalAssetsAfter == 0 && totalSupplyAfter == 0;
            if (isMintingInitialShares || isBurningAllOutstandingShares) {
                return;
            }
        }

        {
            // 1e4 is the max LTV
            uint256 deltaFromInitialLTV = mSAFE_LTV_THRESHOLD.mulDiv(initialLTV, 1e4);
            uint256 upperLimit = MathUpgradeable.min(initialLTV + deltaFromInitialLTV, 1e4);
            uint256 lowerLimit = deltaFromInitialLTV < initialLTV ? initialLTV - deltaFromInitialLTV : 0;

            if (ltvAfter > upperLimit || ltvAfter < lowerLimit) {
                revert EnforcedSafeLTV(ltvAfter);
            }
        }
    }

    /**
     * @notice Ensures the ratio of `totalAssets`:`totalSupply` (A:S) does
     * @notice     not deviate by more than `SHARES_TO_ASSETS_RATIO_THRESHOLD`
     * @dev Compares the initial A:S ratio against the ratio used when minting/burning
     * @dev Validation should run in 2 cases for mint, and 2 cases for burn:
     * @dev    Mint: Initial mints (`S` == 0) and  subsequent mints (`S` > 0)
     * @dev    Burn: Burning some OR all outstanding shares (resulting in S == 0 or S > 0)
     * @dev Comparing the operation ratio delta rather than the final state ratio delta is superior because
     * @dev  final state ratio delta cannot validate when all outstanding shares are burned
     */
    function _validateSharesToAssetRatio(uint256 initialAssets, uint256 initialSupply) private view {
        (uint256 finalAssets, uint256 finalSupply) = (totalAssets(), totalSupply());

        // Assets:Shares ratio should be 1:1 for initial mint
        if (initialSupply == 0 && finalSupply > 0 && finalAssets * 10 ** _decimalsOffset() != finalSupply) {
            revert ExceededShareToAssetRatioDeltaThreshold();
        }

        // Assets should remain unchanged if shares are unchanged
        if (initialSupply == finalSupply && initialAssets != finalAssets) {
            revert ExceededShareToAssetRatioDeltaThreshold();
        }

        // Ignore if the vault is minting initial shares
        if (initialSupply > 0) {
            uint256 initialRatio = _getSharesToAssetsRatio(initialSupply, initialAssets);
            uint256 ratioDelta;

            {
                (uint256 supplyDelta, uint256 assetsDelta) = (initialSupply < finalSupply)
                    ? (finalSupply - initialSupply, finalAssets - initialAssets) // Mint
                    : (initialSupply - finalSupply, initialAssets - finalAssets); // Burn

                uint256 operationRatio = _getSharesToAssetsRatio(supplyDelta, assetsDelta);
                ratioDelta =
                    MathUpgradeable.max(initialRatio, operationRatio) -
                    MathUpgradeable.min(initialRatio, operationRatio);
            }

            if (ratioDelta > SHARES_TO_ASSETS_RATIO_THRESHOLD) {
                revert ExceededShareToAssetRatioDeltaThreshold();
            }
        }
    }

    function _enforceDeadline(uint256 deadline) private view {
        if (block.timestamp > deadline) {
            revert DeadlineExceeded();
        }
    }

    /// @dev Created separate method to avoid stack too deep error
    function _approveAssetsForDeposit(DefinitiveConstants.Assets memory depositAssets) private {
        address mVAULT = (VAULT);
        uint256 i;
        uint256 length = depositAssets.amounts.length;
        while (i < length) {
            IERC20(depositAssets.addresses[i]).resetAndSafeIncreaseAllowance(
                address(this),
                mVAULT,
                depositAssets.amounts[i]
            );
            unchecked {
                i++;
            }
        }
    }

    /// @dev Created separate method to avoid stack too deep error
    function _withdrawAndTransfer(address receiver, DefinitiveConstants.Assets memory withdrawnAssets) private {
        // Withdraw `withdrawTokens` from the vault to the MultiUserLLSDStrategy
        // Transfer `withdrawTokens` from the MultiUserLLSDStrategy to the receiver
        uint256 i;
        while (i < withdrawnAssets.addresses.length) {
            ILLSDStrategy(VAULT).withdraw(withdrawnAssets.amounts[i], withdrawnAssets.addresses[i]);

            IERC20(withdrawnAssets.addresses[i]).safeTransfer(receiver, withdrawnAssets.amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _wrapDepositedNativeAsset(
        DefinitiveConstants.Assets memory assets
    ) private returns (DefinitiveConstants.Assets memory) {
        uint256 nativeAssetIndex = type(uint256).max;

        {
            uint256 i;
            while (i < assets.addresses.length) {
                if (assets.addresses[i] == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
                    nativeAssetIndex = i;
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }

        if (nativeAssetIndex != type(uint256).max) {
            _wrap(assets.amounts[nativeAssetIndex]);
            // Replace the native asset with the wrapped native asset
            assets.addresses[nativeAssetIndex] = WRAPPED_NATIVE_ASSET_ADDRESS;
            emit NativeAssetWrap(address(this), assets.amounts[nativeAssetIndex], true /* wrappingToNative */);
        }

        return assets;
    }
}
