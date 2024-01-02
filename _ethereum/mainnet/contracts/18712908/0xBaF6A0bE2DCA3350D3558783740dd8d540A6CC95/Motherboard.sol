// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "SafeERC20.sol";
import "IERC20.sol";
import "EnumerableSet.sol";
import "IERC20Upgradeable.sol";
import "SafeERC20Upgradeable.sol";

import "IFeeHandler.sol";
import "IMotherboard.sol";
import "IGyroVault.sol";
import "ILPTokenExchanger.sol";
import "IPAMM.sol";
import "IGyroConfig.sol";
import "IGYDToken.sol";
import "IExternalActionExecutor.sol";
import "IVault.sol";

import "DataTypes.sol";
import "ConfigKeys.sol";
import "ConfigHelpers.sol";
import "Errors.sol";
import "FixedPoint.sol";
import "DecimalScale.sol";
import "ReserveStateExtensions.sol";
import "StringExtensions.sol";

import "ExternalActionExecutor.sol";
import "GovernableUpgradeable.sol";

/// @title MotherBoard is the central contract connecting the different pieces
/// of the Gyro protocol
contract Motherboard is IMotherboard, GovernableUpgradeable {
    using FixedPoint for uint256;
    using DecimalScale for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for IGYDToken;
    using ConfigHelpers for IGyroConfig;
    using EnumerableSet for EnumerableSet.AddressSet;
    using ReserveStateExtensions for DataTypes.ReserveState;
    using ReserveStateExtensions for DataTypes.VaultInfo;
    using StringExtensions for string;

    uint256 internal constant _REDEEM_DEVIATION_EPSILON = 1e13; // 0.001 %

    /// @inheritdoc IMotherboard
    IGYDToken public immutable override gydToken;

    /// @inheritdoc IMotherboard
    IReserve public immutable override reserve;

    /// @inheritdoc IMotherboard
    IGyroConfig public immutable override gyroConfig;

    /// @notice Used to execute permits and other actions, such as oracle updates,
    /// that do not require any privilege
    IExternalActionExecutor public immutable externalActionExecutor;

    // Balancer vault used for re-entrancy check.
    IVault internal immutable balancerVault;

    /// @inheritdoc IMotherboard
    uint256 public override bootstrappingSupply;

    // Events
    event Mint(
        address indexed minter,
        uint256 mintedGYDAmount,
        uint256 usdValue,
        DataTypes.Order orderBeforeFees,
        DataTypes.Order orderAfterFees
    );

    event Redeem(
        address indexed redeemer,
        uint256 gydToRedeem,
        uint256 usdValueToRedeem,
        DataTypes.Order orderBeforeFees,
        DataTypes.Order orderAfterFees
    );

    constructor(IGyroConfig _gyroConfig) {
        gyroConfig = _gyroConfig;
        gydToken = _gyroConfig.getGYDToken();
        reserve = _gyroConfig.getReserve();
        balancerVault = _gyroConfig.getBalancerVault();
        externalActionExecutor = new ExternalActionExecutor();
    }

    /// @inheritdoc IMotherboard
    function mint(DataTypes.MintAsset[] calldata assets, uint256 minReceivedAmount)
        public
        override
        returns (uint256 mintedGYDAmount)
    {
        _ensureBalancerVaultNotReentrant();

        DataTypes.MonetaryAmount[] memory vaultAmounts = _convertMintInputAssetsToVaultTokens(
            assets
        );
        DataTypes.ReserveState memory reserveState = gyroConfig
            .getReserveManager()
            .getReserveState();

        // order matters!
        gyroConfig.getReserveStewardshipIncentives().checkpoint(reserveState);
        gyroConfig.getGydRecovery().checkAndRun(reserveState);

        DataTypes.Order memory order = _monetaryAmountsToMintOrder(
            vaultAmounts,
            reserveState.vaults
        );

        gyroConfig.getRootSafetyCheck().checkAndPersistMint(order);

        for (uint256 i = 0; i < vaultAmounts.length; i++) {
            DataTypes.MonetaryAmount memory vaultAmount = vaultAmounts[i];
            IERC20(vaultAmount.tokenAddress).safeTransfer(address(reserve), vaultAmount.amount);
        }

        DataTypes.Order memory orderAfterFees = gyroConfig.getFeeHandler().applyFees(order);

        uint256 usdValue = _getBasketUSDValue(orderAfterFees);
        mintedGYDAmount = pamm().mint(usdValue, reserveState.totalUSDValue);

        require(mintedGYDAmount >= minReceivedAmount, Errors.TOO_MUCH_SLIPPAGE);
        require(!_isOverCap(mintedGYDAmount), Errors.SUPPLY_CAP_EXCEEDED);

        gydToken.mint(msg.sender, mintedGYDAmount);

        emit Mint(msg.sender, mintedGYDAmount, usdValue, order, orderAfterFees);
    }

    function mint(
        DataTypes.MintAsset[] calldata assets,
        uint256 minReceivedAmount,
        DataTypes.ExternalAction[] calldata actions
    ) public returns (uint256 mintedGYDAmount) {
        externalActionExecutor.executeActions(actions);
        return mint(assets, minReceivedAmount);
    }

    /// @inheritdoc IMotherboard
    function redeem(uint256 gydToRedeem, DataTypes.RedeemAsset[] calldata assets)
        public
        override
        returns (uint256[] memory outputAmounts)
    {
        _ensureBalancerVaultNotReentrant();

        // Catch a corner case where the complete minted supply and some of the bootstrapping supply
        // is redeemed, which would make mintedSupply() underflow in following calls.
        require(gydToRedeem <= mintedSupply(), Errors.TRYING_TO_REDEEM_MORE_THAN_SUPPLY);

        DataTypes.ReserveState memory reserveState = gyroConfig
            .getReserveManager()
            .getReserveState();

        uint256 reserveRedeemUSDValue = reserveState.computeLowerBoundUSDValue(_oracle());

        // order matters!
        gyroConfig.getReserveStewardshipIncentives().checkpoint(reserveState);
        gyroConfig.getGydRecovery().checkAndRun(reserveState);

        uint256 usdValueToRedeem = pamm().redeem(gydToRedeem, reserveRedeemUSDValue);
        require(
            usdValueToRedeem <= gydToRedeem.mulDown(FixedPoint.ONE + _REDEEM_DEVIATION_EPSILON),
            Errors.REDEEM_AMOUNT_BUG
        );

        gydToken.burnFrom(msg.sender, gydToRedeem);

        DataTypes.Order memory order = _createRedeemOrder(
            usdValueToRedeem,
            assets,
            reserveState.vaults
        );
        gyroConfig.getRootSafetyCheck().checkAndPersistRedeem(order);

        DataTypes.Order memory orderAfterFees = gyroConfig.getFeeHandler().applyFees(order);
        outputAmounts = _convertAndSendRedeemOutputAssets(assets, orderAfterFees);

        emit Redeem(msg.sender, gydToRedeem, usdValueToRedeem, order, orderAfterFees);
    }

    function redeem(
        uint256 gydToRedeem,
        DataTypes.RedeemAsset[] calldata assets,
        DataTypes.ExternalAction[] calldata actions
    ) external returns (uint256[] memory outputAmounts) {
        externalActionExecutor.executeActions(actions);
        return redeem(gydToRedeem, assets);
    }

    /// @inheritdoc IMotherboard
    function dryMint(DataTypes.MintAsset[] calldata assets, uint256 minReceivedAmount)
        external
        view
        override
        returns (uint256 mintedGYDAmount, string memory err)
    {
        DataTypes.MonetaryAmount[] memory vaultAmounts;
        (vaultAmounts, err) = _dryConvertMintInputAssetsToVaultTokens(assets);
        if (bytes(err).length > 0) {
            return (0, err);
        }

        DataTypes.ReserveState memory reserveState = gyroConfig
            .getReserveManager()
            .getReserveState();

        DataTypes.Order memory order = _monetaryAmountsToMintOrder(
            vaultAmounts,
            reserveState.vaults
        );

        err = gyroConfig.getRootSafetyCheck().isMintSafe(order);
        if (bytes(err).length > 0) {
            return (0, err);
        }

        DataTypes.Order memory orderAfterFees = gyroConfig.getFeeHandler().applyFees(order);
        uint256 usdValue = _getBasketUSDValue(orderAfterFees);
        mintedGYDAmount = pamm().computeMintAmount(usdValue, reserveState.totalUSDValue);

        if (mintedGYDAmount < minReceivedAmount) {
            return (mintedGYDAmount, Errors.TOO_MUCH_SLIPPAGE);
        }

        if (_isOverCap(mintedGYDAmount)) {
            return (mintedGYDAmount, Errors.SUPPLY_CAP_EXCEEDED);
        }
    }

    /// @inheritdoc IMotherboard
    function dryRedeem(uint256 gydToRedeem, DataTypes.RedeemAsset[] calldata assets)
        external
        view
        override
        returns (uint256[] memory outputAmounts, string memory err)
    {
        outputAmounts = new uint256[](assets.length);

        if (gydToRedeem > mintedSupply()) {
            return (outputAmounts, Errors.TRYING_TO_REDEEM_MORE_THAN_SUPPLY);
        }

        DataTypes.ReserveState memory reserveState = gyroConfig
            .getReserveManager()
            .getReserveState();
        uint256 reserveRedeemUSDValue = reserveState.computeLowerBoundUSDValue(_oracle());
        uint256 usdValueToRedeem = pamm().computeRedeemAmount(gydToRedeem, reserveRedeemUSDValue);

        DataTypes.Order memory order = _createRedeemOrder(
            usdValueToRedeem,
            assets,
            reserveState.vaults
        );
        err = gyroConfig.getRootSafetyCheck().isRedeemSafe(order);
        if (bytes(err).length > 0) {
            return (outputAmounts, err);
        }
        DataTypes.Order memory orderAfterFees = gyroConfig.getFeeHandler().applyFees(order);
        return _computeRedeemOutputAmounts(assets, orderAfterFees);
    }

    /// @inheritdoc IMotherboard
    function pamm() public view override returns (IPAMM) {
        return gyroConfig.getPAMM();
    }

    function mintStewardshipIncRewards(uint256 amount) external override {
        require(
            msg.sender == address(gyroConfig.getReserveStewardshipIncentives()),
            Errors.NOT_AUTHORIZED
        );
        address treasury = gyroConfig.getGovTreasuryAddress();
        gydToken.mint(treasury, amount);
    }

    function _dryConvertMintInputAssetsToVaultTokens(DataTypes.MintAsset[] calldata assets)
        internal
        view
        returns (DataTypes.MonetaryAmount[] memory vaultAmounts, string memory err)
    {
        vaultAmounts = new DataTypes.MonetaryAmount[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            DataTypes.MintAsset calldata asset = assets[i];
            uint256 vaultTokenAmount;
            (vaultTokenAmount, err) = _computeVaultTokensForAsset(asset);
            if (bytes(err).length > 0) {
                return (vaultAmounts, err);
            }
            vaultAmounts[i] = DataTypes.MonetaryAmount({
                tokenAddress: asset.destinationVault,
                amount: vaultTokenAmount
            });
        }
    }

    function _computeVaultTokensForAsset(DataTypes.MintAsset calldata asset)
        internal
        view
        returns (uint256, string memory err)
    {
        if (asset.inputToken == asset.destinationVault) {
            return (asset.inputAmount, "");
        } else {
            IGyroVault vault = IGyroVault(asset.destinationVault);
            if (asset.inputToken == vault.underlying()) {
                return vault.dryDeposit(asset.inputAmount, 0);
            } else {
                return (0, Errors.INVALID_ASSET);
            }
        }
    }

    function _convertMintInputAssetsToVaultTokens(DataTypes.MintAsset[] calldata assets)
        internal
        returns (DataTypes.MonetaryAmount[] memory)
    {
        DataTypes.MonetaryAmount[] memory vaultAmounts = new DataTypes.MonetaryAmount[](
            assets.length
        );

        for (uint256 i = 0; i < assets.length; i++) {
            DataTypes.MintAsset calldata asset = assets[i];
            vaultAmounts[i] = DataTypes.MonetaryAmount({
                tokenAddress: asset.destinationVault,
                amount: _convertMintInputAssetToVaultToken(asset)
            });
        }
        return vaultAmounts;
    }

    function _convertMintInputAssetToVaultToken(DataTypes.MintAsset calldata asset)
        internal
        returns (uint256)
    {
        IGyroVault vault = IGyroVault(asset.destinationVault);

        IERC20(asset.inputToken).safeTransferFrom(msg.sender, address(this), asset.inputAmount);

        if (asset.inputToken == address(vault)) {
            return asset.inputAmount;
        }

        address lpTokenAddress = vault.underlying();
        require(asset.inputToken == lpTokenAddress, Errors.INVALID_ASSET);

        IERC20(lpTokenAddress).safeIncreaseAllowance(address(vault), asset.inputAmount);
        return vault.deposit(asset.inputAmount, 0);
    }

    function _getAssetAmountMint(address vault, DataTypes.MonetaryAmount[] memory amounts)
        internal
        pure
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            DataTypes.MonetaryAmount memory vaultAmount = amounts[i];
            if (vaultAmount.tokenAddress == vault) total += vaultAmount.amount;
        }
        return total;
    }

    function _monetaryAmountsToMintOrder(
        DataTypes.MonetaryAmount[] memory amounts,
        DataTypes.VaultInfo[] memory vaultsInfo
    ) internal pure returns (DataTypes.Order memory) {
        DataTypes.Order memory order = DataTypes.Order({
            mint: true,
            vaultsWithAmount: new DataTypes.VaultWithAmount[](vaultsInfo.length)
        });

        for (uint256 i = 0; i < vaultsInfo.length; i++) {
            DataTypes.VaultInfo memory vaultInfo = vaultsInfo[i];
            order.vaultsWithAmount[i] = DataTypes.VaultWithAmount({
                amount: _getAssetAmountMint(vaultInfo.vault, amounts),
                vaultInfo: vaultInfo
            });
        }

        return order;
    }

    function _getRedeemAssetAmountAndRatio(
        DataTypes.VaultInfo memory vaultInfo,
        uint256 usdValueToRedeem,
        DataTypes.RedeemAsset[] calldata redeemAssets
    ) internal view returns (uint256, uint256) {
        for (uint256 i = 0; i < redeemAssets.length; i++) {
            DataTypes.RedeemAsset calldata asset = redeemAssets[i];
            if (asset.originVault == vaultInfo.vault) {
                uint256 vaultPrice = vaultInfo.computeUpperBoundUSDPrice(_oracle());
                uint256 vaultUsdValueToWithdraw = usdValueToRedeem.mulDown(asset.valueRatio);
                uint256 vaultTokenAmount = vaultUsdValueToWithdraw.divDown(vaultPrice);
                uint256 scaledVaultTokenAmount = vaultTokenAmount.scaleTo(vaultInfo.decimals);

                return (scaledVaultTokenAmount, asset.valueRatio);
            }
        }
        return (0, 0);
    }

    function _createRedeemOrder(
        uint256 usdValueToRedeem,
        DataTypes.RedeemAsset[] calldata assets,
        DataTypes.VaultInfo[] memory vaultsInfo
    ) internal view returns (DataTypes.Order memory) {
        _ensureNoDuplicates(assets);

        DataTypes.Order memory order = DataTypes.Order({
            mint: false,
            vaultsWithAmount: new DataTypes.VaultWithAmount[](vaultsInfo.length)
        });

        uint256 totalValueRatio = 0;

        for (uint256 i = 0; i < vaultsInfo.length; i++) {
            DataTypes.VaultInfo memory vaultInfo = vaultsInfo[i];
            (uint256 amount, uint256 valueRatio) = _getRedeemAssetAmountAndRatio(
                vaultInfo,
                usdValueToRedeem,
                assets
            );
            totalValueRatio += valueRatio;

            order.vaultsWithAmount[i] = DataTypes.VaultWithAmount({
                amount: amount,
                vaultInfo: vaultInfo
            });
        }

        require(totalValueRatio == FixedPoint.ONE, Errors.INVALID_ARGUMENT);

        return order;
    }

    function _convertAndSendRedeemOutputAssets(
        DataTypes.RedeemAsset[] calldata assets,
        DataTypes.Order memory order
    ) internal returns (uint256[] memory outputAmounts) {
        outputAmounts = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            DataTypes.RedeemAsset memory asset = assets[i];
            uint256 vaultTokenAmount = _getRedeemAmount(order.vaultsWithAmount, asset.originVault);
            uint256 outputAmount = _convertRedeemOutputAsset(asset, vaultTokenAmount);
            // ensure we received enough tokens and transfer them to the user
            require(outputAmount >= asset.minOutputAmount, Errors.TOO_MUCH_SLIPPAGE);
            outputAmounts[i] = outputAmount;

            IERC20(asset.outputToken).safeTransfer(msg.sender, outputAmount);
        }
    }

    function _getRedeemAmount(DataTypes.VaultWithAmount[] memory vaultsWithAmount, address vault)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < vaultsWithAmount.length; i++) {
            DataTypes.VaultWithAmount memory vaultWithAmount = vaultsWithAmount[i];
            if (vaultWithAmount.vaultInfo.vault == vault) {
                return vaultWithAmount.amount;
            }
        }
        return 0;
    }

    function _convertRedeemOutputAsset(DataTypes.RedeemAsset memory asset, uint256 vaultTokenAmount)
        internal
        returns (uint256)
    {
        IGyroVault vault = IGyroVault(asset.originVault);
        // withdraw the amount of vault tokens from the reserve
        reserve.withdrawToken(address(vault), vaultTokenAmount);

        // nothing to do if the user wants the vault token
        if (asset.outputToken == address(vault)) {
            return vaultTokenAmount;
        } else {
            // otherwise, convert the vault token into its underlying LP token
            require(asset.outputToken == vault.underlying(), Errors.INVALID_ASSET);
            return vault.withdraw(vaultTokenAmount, 0);
        }
    }

    function _computeRedeemOutputAmounts(
        DataTypes.RedeemAsset[] calldata assets,
        DataTypes.Order memory order
    ) internal view returns (uint256[] memory outputAmounts, string memory err) {
        outputAmounts = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            DataTypes.RedeemAsset calldata asset = assets[i];
            uint256 vaultTokenAmount = _getRedeemAmount(order.vaultsWithAmount, asset.originVault);
            uint256 outputAmount;
            (outputAmount, err) = _computeRedeemOutputAmount(asset, vaultTokenAmount);
            if (bytes(err).length > 0) {
                return (outputAmounts, err);
            }
            // ensure we received enough tokens and transfer them to the user
            if (outputAmount < asset.minOutputAmount) {
                return (outputAmounts, Errors.TOO_MUCH_SLIPPAGE);
            }
            outputAmounts[i] = outputAmount;
        }
    }

    function _computeRedeemOutputAmount(
        DataTypes.RedeemAsset calldata asset,
        uint256 vaultTokenAmount
    ) internal view returns (uint256 outputAmount, string memory err) {
        IGyroVault vault = IGyroVault(asset.originVault);

        // nothing to do if the user wants the vault token
        if (asset.outputToken == address(vault)) {
            return (vaultTokenAmount, "");
        }

        // otherwise, we need the outputToken to be the underlying LP token
        // and to convert the vault token into the underlying LP token
        if (asset.outputToken != vault.underlying()) {
            return (0, Errors.INVALID_ASSET);
        }

        uint256 vaultTokenBalance = vault.balanceOf(address(reserve));
        if (vaultTokenBalance < vaultTokenAmount) {
            return (0, Errors.INSUFFICIENT_BALANCE);
        }

        return vault.dryWithdraw(vaultTokenAmount, 0);
    }

    function _getBasketUSDValue(DataTypes.Order memory order)
        internal
        view
        returns (uint256 result)
    {
        for (uint256 i = 0; i < order.vaultsWithAmount.length; i++) {
            DataTypes.VaultWithAmount memory vaultWithAmount = order.vaultsWithAmount[i];
            DataTypes.VaultInfo memory vaultInfo = vaultWithAmount.vaultInfo;
            uint256 vaultPrice = vaultInfo.computeLowerBoundUSDPrice(_oracle());
            uint256 scaledAmount = vaultWithAmount.amount.scaleFrom(vaultInfo.decimals);
            result += scaledAmount.mulDown(vaultPrice);
        }
    }

    function _ensureNoDuplicates(DataTypes.RedeemAsset[] calldata redeemAssets) internal pure {
        for (uint256 i = 0; i < redeemAssets.length; i++) {
            DataTypes.RedeemAsset calldata asset = redeemAssets[i];
            for (uint256 j = i + 1; j < redeemAssets.length; j++) {
                DataTypes.RedeemAsset calldata otherAsset = redeemAssets[j];
                require(asset.originVault != otherAsset.originVault, Errors.INVALID_ARGUMENT);
            }
        }
    }

    /// @dev Ensures that this is not called from inside a Balancer vault operation. This avoids a reentrancy condition.
    function _ensureBalancerVaultNotReentrant() internal {
        // A simple no-op that would trip the Vault's reentrancy check. The code "withdraws" an amount of 0 of token
        // address(0) from the Vault’s internal balance for the calling contract and sends it to address(0).
        IVault.UserBalanceOp[] memory ops = new IVault.UserBalanceOp[](1);
        ops[0].kind = IVault.UserBalanceOpKind.WITHDRAW_INTERNAL;
        ops[0].sender = address(this);
        balancerVault.manageUserBalance(ops);
    }

    function mintedSupply() public view returns (uint256) {
        return gydToken.totalSupply() - bootstrappingSupply;
    }

    function setBootstrappingSupply(uint256 _bootstrappingSupply) external governanceOnly {
        bootstrappingSupply = _bootstrappingSupply;
    }

    function _isOverCap(uint256 mintedGYDAmount) internal view returns (bool) {
        uint256 globalSupplyCap = gyroConfig.getGlobalSupplyCap();
        return gydToken.totalSupply() + mintedGYDAmount > globalSupplyCap;
    }

    function _oracle() internal view returns (IBatchVaultPriceOracle) {
        return gyroConfig.getRootPriceOracle();
    }
}
