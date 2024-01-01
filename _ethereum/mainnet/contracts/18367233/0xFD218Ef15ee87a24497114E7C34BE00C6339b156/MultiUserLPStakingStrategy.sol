// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ERC20Upgradeable.sol";

import "./MathUpgradeable.sol";
import "./DefinitiveErrors.sol";
import "./ERC20.sol";

import "./DefinitiveConstants.sol";
import "./DefinitiveAssets.sol";
import "./ILPStakingStrategyV1.sol";
import "./IBaseTransfersNativeV1.sol";
import "./IBaseSafeHarborMode.sol";
import "./BaseMultiUserStrategyV1.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./IMultiUserLPStakingStrategyV1.sol";
import "./StorageSlotUpgradeable.sol";

interface ILPStakingStrategy is ILPStakingStrategyV1, IBaseTransfersNativeV1, IBaseSafeHarborMode {
    function DEFAULT_ADMIN_ROLE() external returns (bytes32);
}

contract MultiUserLPStakingStrategy is IMultiUserLPStakingStrategyV1, BaseMultiUserStrategyV1 {
    using DefinitiveAssets for IERC20;
    using MathUpgradeable for uint256;

    /// @dev If a BaseMultiUserShares is created, move these items to that class and inherit from it
    /// @dev Doing so will preserve the storage locations and clean up this contract
    IERC20Upgradeable private _asset;
    uint8 private _underlyingDecimals;
    uint256[49] private __gap;

    address[] public UNDERLYING_ASSETS;
    uint256 public UNDERLYING_ASSETS_COUNT;
    address[] public SAFE_ASSETS;
    uint256 public SAFE_ASSETS_COUNT;

    /// @notice Defines the ABI version of MultiUserLPStakingStrategy
    uint256 public constant ABI_VERSION = 1;

    /// @notice Constructor on the implementation contract should call _disableInitializers()
    /// @dev https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/2
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev ALWAYS INCLUDE VAULT: To maintain MU_* and Vault relationship during upgrades
    function initialize(
        address payable _vault,
        string memory _name,
        string memory _symbol,
        address _feeAccount
    ) public initializer {
        __BaseMultiUserStrategy_init(address(_vault), _name, _symbol, _feeAccount);

        IERC20Upgradeable mAsset = IERC20Upgradeable(ILPStakingStrategy(_vault).LP_TOKEN());
        _asset = mAsset;
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(mAsset);
        _underlyingDecimals = success ? assetDecimals : 18;

        uint256 mUNDERLYING_ASSETS_COUNT = ILPStakingStrategy(VAULT).LP_UNDERLYING_TOKENS_COUNT();
        UNDERLYING_ASSETS_COUNT = mUNDERLYING_ASSETS_COUNT;
        UNDERLYING_ASSETS = new address[](mUNDERLYING_ASSETS_COUNT);

        uint256 i;
        while (i < mUNDERLYING_ASSETS_COUNT) {
            UNDERLYING_ASSETS[i] = ILPStakingStrategy(_vault).LP_UNDERLYING_TOKENS(i);
            unchecked {
                i++;
            }
        }

        SAFE_ASSETS = UNDERLYING_ASSETS;
        SAFE_ASSETS_COUNT = mUNDERLYING_ASSETS_COUNT;
    }

    // OZ:4626 Start
    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     */
    function decimals() public view virtual override(IERC20MetadataUpgradeable, ERC20Upgradeable) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address _owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(_owner), MathUpgradeable.Rounding.Down);
    }

    function maxRedeem(address _owner) public view virtual override returns (uint256) {
        return balanceOf(_owner);
    }

    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }

    function _tryGetAssetDecimals(IERC20Upgradeable asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20MetadataUpgradeable.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    // OZ:4626 End

    function setSafeAssets(address[] calldata _safeAssets) external onlyDefinitiveVaultAdmins {
        {
            uint256 i;
            uint256 length = _safeAssets.length;
            if (length == 0) {
                revert InvalidInputs();
            }

            while (i < length) {
                if (_safeAssets[i] == address(0)) {
                    revert InvalidInputs();
                }
                unchecked {
                    ++i;
                }
            }
        }

        SAFE_ASSETS = _safeAssets;
        SAFE_ASSETS_COUNT = _safeAssets.length;

        emit SafeAssetsUpdated(_msgSender(), _safeAssets);
    }

    function deposit(uint256 assets, address receiver) public revertIfSafeHarborModeEnabled returns (uint256 shares) {
        if (assets > maxDeposit(receiver)) {
            revert DepositMoreThanMax();
        }

        shares = previewDeposit(assets);
        if (shares == 0) {
            revert ZeroShares();
        }

        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function mint(uint256 shares, address receiver) public revertIfSafeHarborModeEnabled returns (uint256 assets) {
        if (shares > maxMint(receiver)) {
            revert MintMoreThanMax();
        }

        if (shares == 0) {
            revert ZeroShares();
        }

        assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) public revertIfSafeHarborModeEnabled returns (uint256 shares) {
        if (assets > maxWithdraw(_owner)) {
            revert WithdrawMoreThanMax();
        }

        shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, _owner, assets, shares, additionalFeePct);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) public revertIfSafeHarborModeEnabled returns (uint256 assets) {
        if (shares > maxRedeem(_owner)) {
            revert RedeemMoreThanMax();
        }

        assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, _owner, assets, shares, additionalFeePct);
    }

    function totalAssets() public view virtual returns (uint256) {
        return ILPStakingStrategy(VAULT).getAmountStaked();
    }

    function depositUnderlying(
        uint256[] calldata amounts,
        uint256 minAmount,
        address receiver
    ) public payable virtual nonReentrant revertIfSafeHarborModeEnabled returns (uint256 shares) {
        _transferUnderlyingAssetsFrom(amounts);
        _approveUnderlyingForDeposit(amounts);

        // Deposit to vault
        ILPStakingStrategy(VAULT).deposit{ value: msg.value }(amounts, UNDERLYING_ASSETS);

        // Add liquidity to vault
        uint256 assets = ILPStakingStrategy(VAULT).addLiquidity(amounts, minAmount);

        /// @notice Calculate shares AFTER adding liquidity and BEFORE minting
        /// @dev `previewDeposit` calculates using the amount staked before additional liquidity is added
        shares = previewDeposit(assets);

        if (shares == 0) {
            revert ZeroShares();
        }

        ILPStakingStrategy(VAULT).stake(assets);

        _mint(receiver, shares);

        emit DepositUnderlying(_msgSender(), receiver, amounts, shares);
    }

    /**
     * Redeem shares for underlying assets
     * @param shares Total shares to redeem; Should include fees (Redeemed Shares + Fee Shares)
     * @param minAmounts minAmounts for each asset; Should exclude fees
     *          (`removeLiquidity` will be called with `shares - feeShares`)
     * @param receiver address
     * @param _owner address
     * @return assetAddresses
     * @return amounts
     */
    function redeemUnderlying(
        uint256 shares,
        uint256[] calldata minAmounts,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) public nonReentrant returns (address[] memory assetAddresses, uint256[] memory amounts) {
        if (shares > maxRedeem(_owner)) {
            revert RedeemMoreThanMax();
        }

        uint256 assets = previewRedeem(shares);

        (assetAddresses, amounts) = _withdrawUnderlying(
            _msgSender(),
            receiver,
            _owner,
            assets,
            minAmounts,
            shares,
            additionalFeePct
        );
    }

    /**
     *
     * @param shares Total shares to redeem; Should include fees (Redeemed Shares + Fee Shares)
     * @param index uint8
     * @param minAmount minAmount for selected asset; Should exclude fees
     *          (`removeLiquidity` will be called with `shares - feeShares`)
     * @param receiver address
     * @param _owner address
     * @return assetAddress
     * @return amount
     */
    function redeemOneUnderlying(
        uint256 shares,
        uint8 index,
        uint256 minAmount,
        address receiver,
        address _owner,
        uint256 additionalFeePct
    ) public nonReentrant revertIfSafeHarborModeEnabled returns (address assetAddress, uint256 amount) {
        if (shares > maxRedeem(_owner)) {
            revert RedeemMoreThanMax();
        }

        uint256 assets = previewRedeem(shares);

        (assetAddress, amount) = _withdrawOneUnderlying(
            _msgSender(),
            receiver,
            _owner,
            assets,
            index,
            minAmount,
            shares,
            additionalFeePct
        );
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        IERC20(asset()).safeTransferFrom(caller, address(this), assets);

        (uint256[] memory assetAmounts, address[] memory assetAddresses) = (new uint256[](1), new address[](1));
        (assetAmounts[0], assetAddresses[0]) = (assets, asset());

        IERC20(asset()).resetAndSafeIncreaseAllowance(address(this), address(VAULT), assets);

        ILPStakingStrategy(VAULT).deposit(assetAmounts, assetAddresses);

        // `previewDeposit`/`previewMint` calculates using the amount staked before additional liquidity is added
        // Shares must be calculated BEFORE staking
        ILPStakingStrategy(VAULT).stake(assets);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint256 shares,
        uint256 additionalFeePct
    ) internal {
        if (caller != _owner) {
            _spendAllowance(_owner, caller, shares);
        }

        /// @dev If fees are enabled, handle fees then recalculate shares and assets
        (shares, assets) = _handleRedemptionFees(_owner, shares, additionalFeePct);

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(_owner, shares);

        ILPStakingStrategy(VAULT).unstake(assets);
        ILPStakingStrategy(VAULT).withdraw(assets, asset());

        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, _owner, assets, shares);
    }

    function _withdrawUnderlying(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint256[] calldata minAmounts,
        uint256 shares,
        uint256 additionalFeePct
    ) internal returns (address[] memory assetAddresses, uint256[] memory amounts) {
        if (caller != _owner) {
            _spendAllowance(_owner, caller, shares);
        }

        /// @dev If fees are enabled, handle fees then recalculate shares and assets
        (shares, assets) = _handleRedemptionFees(_owner, shares, additionalFeePct);

        // Get total supply before burning shares
        uint256 mPreviousTotalSupply = totalSupply();

        _burn(_owner, shares);

        if (ILPStakingStrategy(VAULT).SAFE_HARBOR_MODE_ENABLED()) {
            if (!bool(StorageSlotUpgradeable.getBooleanSlot(_ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT).value)) {
                revert SafeHarborRedemptionDisabled();
            }
            assetAddresses = SAFE_ASSETS;
            amounts = new uint256[](assetAddresses.length);
            uint256 length = amounts.length;
            uint256 i;
            while (i < length) {
                uint256 balance = ILPStakingStrategy(VAULT).getBalance(assetAddresses[i]);
                amounts[i] = ((balance * shares) / mPreviousTotalSupply);
                unchecked {
                    i++;
                }
            }
        } else {
            assetAddresses = UNDERLYING_ASSETS;
            amounts = ILPStakingStrategy(VAULT).exit(assets, minAmounts);
        }

        {
            uint256 i;
            while (i < assetAddresses.length) {
                if (amounts[i] > 0) {
                    // Withdraw from vault to this contract
                    ILPStakingStrategy(VAULT).withdraw(amounts[i], assetAddresses[i]);

                    // Send to receiver
                    _transferAsset(receiver, assetAddresses[i], amounts[i]);
                }

                unchecked {
                    i++;
                }
            }
        }

        emit WithdrawUnderlying(caller, receiver, _owner, amounts, assetAddresses, shares);
    }

    function _withdrawOneUnderlying(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint8 index,
        uint256 minAmount,
        uint256 shares,
        uint256 additionalFeePct
    ) internal returns (address assetAddress, uint256 amount) {
        if (caller != _owner) {
            _spendAllowance(_owner, caller, shares);
        }

        /// @dev If fees are enabled, handle fees then recalculate shares and assets
        (shares, assets) = _handleRedemptionFees(_owner, shares, additionalFeePct);

        _burn(_owner, shares);

        amount = ILPStakingStrategy(VAULT).exitOne(assets, minAmount, index);

        assetAddress = UNDERLYING_ASSETS[index];

        // Withdraw from vault to this contract
        ILPStakingStrategy(VAULT).withdraw(amount, assetAddress);

        _transferAsset(receiver, assetAddress, amount);

        emit WithdrawOneUnderlying(_msgSender(), receiver, _owner, amount, index, assets);
    }

    function _transferAsset(address recipient, address assetAddress, uint256 amount) internal {
        if (assetAddress == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            DefinitiveAssets.safeTransferETH(payable(recipient), amount);
        } else {
            IERC20(assetAddress).safeTransfer(recipient, amount);
        }
    }

    function _transferUnderlyingAssetsFrom(uint256[] memory amounts) internal {
        address[] memory assetAddresses = UNDERLYING_ASSETS;
        uint256 assetAddressesLength = assetAddresses.length;
        if (amounts.length != assetAddressesLength) {
            revert InvalidInputs();
        }
        bool hasNativeAsset;
        uint256 nativeAssetIndex;

        for (uint256 i; i < assetAddressesLength; ) {
            if (UNDERLYING_ASSETS[i] == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
                nativeAssetIndex = i;
                hasNativeAsset = true;
                unchecked {
                    ++i;
                }
                continue;
            }
            // ERC20 tokens
            if (amounts[i] > 0) {
                IERC20(UNDERLYING_ASSETS[i]).safeTransferFrom(_msgSender(), address(this), amounts[i]);
            }
            unchecked {
                ++i;
            }
        }
        // Revert if NATIVE_ASSET_ADDRESS is not in assetAddresses and msg.value is not zero
        if (!hasNativeAsset && msg.value != 0) {
            revert InvalidMsgValue();
        }

        // Revert if depositing native asset and amount != msg.value
        if (hasNativeAsset && msg.value != amounts[nativeAssetIndex]) {
            revert InvalidMsgValue();
        }
    }

    function _approveUnderlyingForDeposit(uint256[] memory amounts) internal {
        (
            uint256 mUNDERLYING_ASSETS_COUNT,
            address[] memory mUNDERLYING_ASSETS,
            address mNATIVE_ASSET_ADDRESS,
            address mVAULT
        ) = (UNDERLYING_ASSETS_COUNT, UNDERLYING_ASSETS, DefinitiveConstants.NATIVE_ASSET_ADDRESS, VAULT);

        uint256 i;
        while (i < mUNDERLYING_ASSETS_COUNT) {
            if (amounts[i] > 0 && mUNDERLYING_ASSETS[i] != mNATIVE_ASSET_ADDRESS) {
                IERC20(mUNDERLYING_ASSETS[i]).resetAndSafeIncreaseAllowance(address(this), mVAULT, amounts[i]);
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates the shares and recalculates assets after handling fees
     * @param _owner address
     * @param shares uint256
     * @return shares uint256
     * @return assets uint256
     */
    function _handleRedemptionFees(
        address _owner,
        uint256 shares,
        uint256 additionalFeePct
    ) internal returns (uint256, uint256) {
        shares -= _handleRedemptionFeesOnShares(_owner, address(this), shares, additionalFeePct);

        return (shares, previewRedeem(shares));
    }
}
