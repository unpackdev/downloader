// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./Math.sol";
import "./IERC20Metadata.sol";
import "./IERC721.sol";
import "./SafeCast.sol";

import "./Structs.sol";
import "./DCSStructs.sol";
import "./IOracleEntry.sol";
import "./IAddressManager.sol";
import "./IACLManager.sol";
import "./Errors.sol";

library VaultLogic {
    using SafeCast for uint256;

    // CONSTANTS

    uint128 internal constant DAYS_IN_YEAR = 365;

    uint128 internal constant BPS_DECIMALS = 1e4;

    uint8 internal constant VAULT_DECIMALS = 18;

    uint8 internal constant NATIVE_ASSET_DECIMALS = 18;

    // EVENTS

    event VaultStatusUpdated(
        address indexed vaultAddress,
        VaultStatus vaultStatus
    );

    event DCSSettlementStatusUpdated(
        address indexed vaultAddress,
        SettlementStatus settlementStatus
    );

    event DCSIsPayoffInDepositAssetUpdated(
        address indexed vaultAddress,
        bool isPayoffInDepositAsset
    );

    event DCSDisputeSubmitted(address indexed vaultAddress);

    event DCSDisputeProcessed(
        address indexed vaultAddress,
        bool isDisputeAccepted,
        uint40 timestamp,
        uint128 newPrice
    );

    event OraclePriceOverriden(
        address indexed vaultAddress,
        uint256 timestamp,
        uint256 newPrice
    );

    event DCSVaultRolledOver(address indexed vaultAddress);

    // MODIFIERS

    modifier onlyValidVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) {
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    // VIEW FUNCTIONS

    function totalAssets(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        return cgs.vaults[vaultAddress].totalAssets;
    }

    function convertToAssets(
        uint256 _totalSupply,
        uint128 _totalAssets,
        uint256 _shares
    ) internal pure returns (uint128) {
        // assumption: all assets we support have <= 18 decimals
        return ((_shares * _totalAssets) / _totalSupply).toUint128();
    }

    function convertToAssets(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint256 shares
    ) internal view returns (uint128) {
        uint256 _totalSupply = IERC20(vaultAddress).totalSupply();

        if (_totalSupply == 0) return 0;
        // assumption: all assets we support have <= 18 decimals
        // shares and _totalSupply have 18 decimals
        return
            ((shares * totalAssets(cgs, vaultAddress)) / _totalSupply)
                .toUint128();
    }

    function convertToShares(
        uint256 _totalSupply,
        uint128 _totalAssets,
        uint8 _depositAssetDecimals,
        uint128 assets
    ) internal pure returns (uint256) {
        if (_totalAssets == 0 || _totalSupply == 0) {
            return assets * 10 ** (VAULT_DECIMALS - _depositAssetDecimals);
        } else {
            // _totalSupply has 18 decimals, assets and _totalAssets have the same decimals
            return (_totalSupply * assets) / (_totalAssets);
        }
    }

    function convertToShares(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 assets
    ) internal view returns (uint256) {
        uint256 _totalSupply = IERC20(vaultAddress).totalSupply();
        uint128 _totalAssets = totalAssets(cgs, vaultAddress);

        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        uint8 _depositAssetDecimals = getAssetDecimals(
            getProductDepositAsset(dcsProduct)
        );

        return
            convertToShares(
                _totalSupply,
                _totalAssets,
                _depositAssetDecimals,
                assets
            );
    }

    function getAssetDecimals(address asset) internal view returns (uint8) {
        return
            asset == address(0)
                ? NATIVE_ASSET_DECIMALS
                : IERC20Metadata(asset).decimals();
    }

    /**
     * @notice Calculates the coupon payment accumulated from block.timestamp
     * @param cgs CegaGlobalStorage
     * @param vaultAddress address of vault
     */
    function getCurrentYield(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint40 endDate
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        return
            calculateCouponPayment(
                vault.totalAssets - dcsVault.totalYield,
                vault.tradeStartDate,
                dcsProduct.tenorInSeconds,
                dcsVault.aprBps,
                endDate
            );
    }

    function calculateCouponPayment(
        uint128 underlyingAmount,
        uint40 tradeStartDate,
        uint40 tenorInSeconds,
        uint16 aprBps,
        uint40 endDate
    ) internal pure returns (uint128) {
        uint40 secondsPassed = endDate - tradeStartDate;
        uint40 couponSeconds = secondsPassed < tenorInSeconds
            ? secondsPassed
            : tenorInSeconds;
        return
            ((uint256(underlyingAmount) * couponSeconds * aprBps) /
                (DAYS_IN_YEAR * BPS_DECIMALS * 1 days)).toUint128();
    }

    function calculateLateFee(
        uint128 coupon,
        uint40 startDate,
        uint16 lateFeeBps,
        uint8 daysToStartLateFees,
        uint8 daysToStartAuctionDefault
    ) internal view returns (uint128) {
        uint40 daysLate = getDaysLate(startDate);
        if (daysLate < daysToStartLateFees) {
            return 0;
        } else {
            if (daysLate >= daysToStartAuctionDefault) {
                daysLate = daysToStartAuctionDefault;
            }
            return (coupon * daysLate * lateFeeBps) / (BPS_DECIMALS);
        }
    }

    function getIsDefaulted(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (bool) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        if (dcsVault.settlementStatus != SettlementStatus.Auctioned) {
            return false;
        }
        uint40 startDate = cgs.vaults[vaultAddress].tradeStartDate;
        uint40 daysLate = getDaysLate(startDate);
        return daysLate >= dcsProduct.daysToStartAuctionDefault;
    }

    function getDaysLate(uint40 startDate) internal view returns (uint40) {
        uint40 currentTime = block.timestamp.toUint40();
        if (currentTime < startDate) {
            return 0;
        } else {
            return (currentTime - startDate) / 1 days;
        }
    }

    function isWithdrawalPossible(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (bool) {
        VaultStatus vaultStatus = cgs.vaults[vaultAddress].vaultStatus;
        SettlementStatus settlementStatus = cgs
            .dcsVaults[vaultAddress]
            .settlementStatus;
        return
            vaultStatus == VaultStatus.FeesCollected ||
            vaultStatus == VaultStatus.Zombie ||
            settlementStatus == SettlementStatus.Defaulted;
    }

    // Duplicates DCSProductEntry.sol
    function getProductDepositAsset(
        DCSProduct storage dcsProduct
    ) internal view returns (address) {
        return
            dcsProduct.dcsOptionType == DCSOptionType.BuyLow
                ? dcsProduct.quoteAssetAddress
                : dcsProduct.baseAssetAddress;
    }

    // MUTATIVE FUNCTIONS

    function setVaultStatus(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        VaultStatus status
    ) internal onlyValidVault(cgs, vaultAddress) {
        cgs.vaults[vaultAddress].vaultStatus = status;

        emit VaultStatusUpdated(vaultAddress, status);
    }

    function setVaultSettlementStatus(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        SettlementStatus status
    ) internal {
        cgs.dcsVaults[vaultAddress].settlementStatus = status;

        emit DCSSettlementStatusUpdated(vaultAddress, status);
    }

    function setIsPayoffInDepositAsset(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        bool value
    ) internal {
        cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset = value;
        emit DCSIsPayoffInDepositAssetUpdated(vaultAddress, value);
    }

    function openVaultDeposits(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        require(
            cgs.vaults[vaultAddress].vaultStatus == VaultStatus.DepositsClosed,
            Errors.INVALID_VAULT_STATUS
        );
        setVaultStatus(cgs, vaultAddress, VaultStatus.DepositsOpen);
    }

    function rolloverVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        require(
            vault.vaultStatus == VaultStatus.WithdrawalQueueProcessed,
            Errors.INVALID_VAULT_STATUS
        );
        uint40 tradeEndDate = vault.tradeStartDate + dcsProduct.tenorInSeconds;

        require(tradeEndDate != 0, Errors.INVALID_TRADE_END_DATE);

        if (cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset) {
            delete cgs.oraclePriceOverride[vaultAddress][vault.tradeStartDate];
            delete cgs.oraclePriceOverride[vaultAddress][tradeEndDate];

            vault.tradeStartDate = 0;
            vault.auctionWinner = address(0);
            vault.auctionWinnerTokenId = 0;

            dcsVault.aprBps = 0;
            dcsVault.initialSpotPrice = 0;
            dcsVault.strikePrice = 0;
            setVaultStatus(cgs, vaultAddress, VaultStatus.DepositsClosed);
            setVaultSettlementStatus(
                cgs,
                vaultAddress,
                SettlementStatus.NotAuctioned
            );
        } else {
            setVaultStatus(cgs, vaultAddress, VaultStatus.Zombie);
        }

        emit DCSVaultRolledOver(vaultAddress);
    }

    function calculateFees(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128, uint128, uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint128 totalYield = dcsVault.totalYield;
        uint128 underlyingAmount = vault.totalAssets - totalYield;
        uint128 managementFee = (underlyingAmount *
            dcsProduct.tenorInSeconds *
            vault.managementFeeBps) / (DAYS_IN_YEAR * 1 days * BPS_DECIMALS);
        uint128 yieldFee = (totalYield * vault.yieldFeeBps) / BPS_DECIMALS;
        uint128 totalFee = managementFee + yieldFee;

        return (totalFee, managementFee, yieldFee);
    }

    function disputeVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        address tradeWinnerNFT,
        IACLManager aclManager
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage product = cgs.dcsProducts[vault.productId];

        uint256 tradeStartDate = vault.tradeStartDate;
        uint256 tradeEndDate = vault.tradeStartDate + product.tenorInSeconds;
        uint256 currentTime = block.timestamp;
        VaultStatus vaultStatus = vault.vaultStatus;

        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);

        if (currentTime < tradeEndDate) {
            require(
                msg.sender == vault.auctionWinner ||
                    aclManager.isTraderAdmin(msg.sender),
                Errors.NOT_TRADE_WINNER_OR_TRADER_ADMIN
            );

            require(
                currentTime > tradeStartDate &&
                    currentTime <
                    tradeStartDate +
                        (uint256(product.disputePeriodInHours) * 1 hours),
                Errors.OUTSIDE_DISPUTE_PERIOD
            );
            require(
                vaultStatus == VaultStatus.NotTraded,
                Errors.INVALID_VAULT_STATUS
            );
        } else {
            require(
                msg.sender ==
                    IERC721(tradeWinnerNFT).ownerOf(
                        vault.auctionWinnerTokenId
                    ) ||
                    aclManager.isTraderAdmin((msg.sender)),
                Errors.NOT_TRADE_WINNER_OR_TRADER_ADMIN
            );
            require(
                currentTime <
                    tradeEndDate +
                        (uint256(product.disputePeriodInHours) * 1 hours),
                Errors.OUTSIDE_DISPUTE_PERIOD
            );
            require(
                vaultStatus == VaultStatus.TradeExpired,
                Errors.INVALID_VAULT_STATUS
            );

            // if the vault converted and the MM already settled
            if (dcsVault.isPayoffInDepositAsset == false) {
                require(
                    dcsVault.settlementStatus != SettlementStatus.Settled,
                    Errors.INVALID_SETTLEMENT_STATUS
                );
            }
        }

        vault.isInDispute = true;

        emit DCSDisputeSubmitted(vaultAddress);
    }

    function processDispute(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 newPrice
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage product = cgs.dcsProducts[vault.productId];

        require(vault.isInDispute, Errors.VAULT_NOT_IN_DISPUTE);

        uint40 timestamp;
        if (newPrice != 0) {
            VaultStatus vaultStatus = vault.vaultStatus;

            if (vaultStatus == VaultStatus.NotTraded) {
                timestamp = vault.tradeStartDate;
            } else {
                timestamp = vault.tradeStartDate + product.tenorInSeconds;

                setVaultSettlementStatus(
                    cgs,
                    vaultAddress,
                    SettlementStatus.AwaitingSettlement
                );

                setIsPayoffInDepositAsset(cgs, vaultAddress, true);
            }

            overrideOraclePrice(cgs, vaultAddress, timestamp, newPrice);
        }

        vault.isInDispute = false;

        emit DCSDisputeProcessed(
            vaultAddress,
            newPrice != 0,
            timestamp,
            newPrice
        );
    }

    function overrideOraclePrice(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint40 timestamp,
        uint128 newPrice
    ) internal {
        require(newPrice != 0, Errors.INVALID_PRICE);

        cgs.oraclePriceOverride[vaultAddress][timestamp] = newPrice;

        emit OraclePriceOverriden(vaultAddress, timestamp, newPrice);
    }
}
