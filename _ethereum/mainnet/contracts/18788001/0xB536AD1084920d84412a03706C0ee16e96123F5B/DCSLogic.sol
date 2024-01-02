// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./Math.sol";
import "./IERC20Metadata.sol";
import "./SafeCast.sol";
import "./IERC721AUpgradeable.sol";

import "./Structs.sol";
import "./ITradeWinnerNFT.sol";
import "./DCSStructs.sol";
import "./Transfers.sol";
import "./Errors.sol";
import "./VaultLogic.sol";
import "./ICegaVault.sol";
import "./ITreasury.sol";
import "./IOracleEntry.sol";
import "./IAddressManager.sol";
import "./IRedepositManager.sol";
import "./IWrappingProxy.sol";

library DCSLogic {
    using Transfers for address;
    using SafeCast for uint256;

    // EVENTS

    event DepositProcessed(
        address indexed vaultAddress,
        address receiver,
        uint128 amount
    );

    event WithdrawalQueued(
        address indexed vaultAddress,
        uint256 sharesAmount,
        address owner,
        uint32 nextProductId,
        bool withProxy
    );

    event WithdrawalProcessed(
        address indexed vaultAddress,
        uint256 sharesAmount,
        address owner,
        uint32 nextProductId
    );

    event DCSTradeStarted(
        address indexed vaultAddress,
        address auctionWinner,
        uint128 notionalAmount,
        uint128 yieldAmount
    );

    event DCSVaultFeesCollected(
        address indexed vaultAddress,
        uint128 totalFees,
        uint128 managementFee,
        uint128 yieldFee
    );

    event DCSVaultSettled(
        address indexed vaultAddress,
        address settler,
        uint128 depositedAmount,
        uint128 withdrawnAmount
    );

    // MODIFIERS

    modifier onlyValidVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) {
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    // VIEW FUNCTIONS

    function dcsGetProductDepositAsset(
        DCSProduct storage dcsProduct
    ) internal view returns (address) {
        return
            dcsProduct.dcsOptionType == DCSOptionType.BuyLow
                ? dcsProduct.quoteAssetAddress
                : dcsProduct.baseAssetAddress;
    }

    function getDCSProductDepositAndSwapAsset(
        DCSProduct storage dcsProduct
    )
        internal
        view
        returns (
            address depositAsset,
            address swapAsset,
            DCSOptionType dcsOptionType
        )
    {
        dcsOptionType = dcsProduct.dcsOptionType;

        if (dcsOptionType == DCSOptionType.BuyLow) {
            depositAsset = dcsProduct.quoteAssetAddress;
            swapAsset = dcsProduct.baseAssetAddress;
        } else {
            depositAsset = dcsProduct.baseAssetAddress;
            swapAsset = dcsProduct.quoteAssetAddress;
        }
    }

    function getVaultSettlementAsset(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (address) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        bool isDefaulted = dcsVault.settlementStatus ==
            SettlementStatus.Defaulted;
        if (isDefaulted) {
            return
                dcsProduct.dcsOptionType == DCSOptionType.BuyLow
                    ? dcsProduct.quoteAssetAddress
                    : dcsProduct.baseAssetAddress;
        }
        if (dcsProduct.dcsOptionType == DCSOptionType.BuyLow) {
            return
                dcsVault.isPayoffInDepositAsset
                    ? dcsProduct.quoteAssetAddress
                    : dcsProduct.baseAssetAddress;
        } else {
            return
                dcsVault.isPayoffInDepositAsset
                    ? dcsProduct.baseAssetAddress
                    : dcsProduct.quoteAssetAddress;
        }
    }

    function getSpotPriceAt(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        IAddressManager addressManager,
        uint40 priceTimestamp
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint128 price = cgs.oraclePriceOverride[vaultAddress][priceTimestamp];

        if (price > 0) {
            return price;
        }

        IOracleEntry iOracleEntry = IOracleEntry(
            addressManager.getCegaOracle()
        );

        // We always use baseAsset, even if the deposit asset is quote asset, because we
        // need to express the units of quote asset in terms of base asset
        return
            iOracleEntry.getPrice(
                dcsProduct.baseAssetAddress,
                dcsProduct.quoteAssetAddress,
                priceTimestamp,
                vault.dataSource
            );
    }

    function convertDepositUnitsToSwap(
        uint256 amountToConvert,
        IAddressManager addressManager,
        uint128 conversionPrice,
        uint8 depositAssetDecimals,
        uint8 swapAssetDecimals,
        DCSOptionType dcsOptionType
    ) internal view returns (uint128) {
        IOracleEntry iOracleEntry = IOracleEntry(
            addressManager.getCegaOracle()
        );

        // Calculating the notionalInSwapAsset is different because finalSpotPrice is always
        // in units of quote / base.
        uint256 convertedAmount;
        if (dcsOptionType == DCSOptionType.BuyLow) {
            convertedAmount =
                (
                    (amountToConvert *
                        10 **
                            (swapAssetDecimals +
                                iOracleEntry.getTargetDecimals()))
                ) /
                (conversionPrice * 10 ** depositAssetDecimals);
        } else {
            convertedAmount = ((amountToConvert *
                conversionPrice *
                10 ** (swapAssetDecimals)) /
                (10 **
                    (depositAssetDecimals + iOracleEntry.getTargetDecimals())));
        }
        return convertedAmount.toUint128();
    }

    function isSwapOccurring(
        uint128 finalSpotPrice,
        uint128 strikePrice,
        DCSOptionType dcsOptionType
    ) internal pure returns (bool) {
        if (dcsOptionType == DCSOptionType.BuyLow) {
            return finalSpotPrice < strikePrice;
        } else {
            return finalSpotPrice > strikePrice;
        }
    }

    function calculateVaultFinalPayoff(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        require(
            vault.vaultStatus == VaultStatus.TradeExpired,
            Errors.INVALID_VAULT_STATUS
        );

        if (
            !dcsVault.isPayoffInDepositAsset &&
            dcsVault.settlementStatus != SettlementStatus.Settled
        ) {
            (
                address depositAsset,
                address swapAsset,

            ) = getDCSProductDepositAndSwapAsset(dcsProduct);
            uint8 depositAssetDecimals = VaultLogic.getAssetDecimals(
                depositAsset
            );
            uint8 swapAssetDecimals = VaultLogic.getAssetDecimals(swapAsset);

            return
                convertDepositUnitsToSwap(
                    vault.totalAssets,
                    addressManager,
                    dcsVault.strikePrice,
                    depositAssetDecimals,
                    swapAssetDecimals,
                    dcsProduct.dcsOptionType
                );
        } else {
            // totalAssets already has totalYield included inside, because premium is paid upfront
            return vault.totalAssets;
        }
    }

    // MUTATIVE FUNCTIONS

    function processDepositQueue(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint256 maxProcessCount
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 processCount)
    {
        Vault storage vaultData = cgs.vaults[vaultAddress];
        uint32 productId = vaultData.productId;
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        uint256 totalSupply = ICegaVault(vaultAddress).totalSupply();
        uint128 totalAssets = VaultLogic.totalAssets(cgs, vaultAddress);

        require(
            vaultData.vaultStatus == VaultStatus.DepositsOpen,
            Errors.INVALID_VAULT_STATUS
        );
        require(
            !(totalAssets == 0 && totalSupply > 0),
            Errors.VAULT_IN_ZOMBIE_STATE
        );

        DepositQueue storage queue = cgs.dcsDepositQueues[productId];
        uint256 queueLength = queue.depositors.length;
        uint256 index = queue.processedIndex;
        processCount = maxProcessCount == 0
            ? queueLength - index
            : Math.min(queueLength - index, maxProcessCount);

        uint128 totalDepositsAmount;

        for (uint256 i = 0; i < processCount; i++) {
            address depositor = queue.depositors[index + i];
            uint128 depositAmount = queue.amounts[depositor];

            totalDepositsAmount += depositAmount;

            uint256 sharesAmount = VaultLogic.convertToShares(
                totalSupply,
                totalAssets,
                VaultLogic.getAssetDecimals(
                    dcsGetProductDepositAsset(dcsProduct)
                ),
                depositAmount
            );
            ICegaVault(vaultAddress).mint(depositor, sharesAmount);

            delete queue.amounts[depositor];

            emit DepositProcessed(vaultAddress, depositor, depositAmount);
        }
        queue.processedIndex += processCount.toUint128();

        queue.queuedDepositsTotalAmount -= totalDepositsAmount;

        dcsProduct.sumVaultUnderlyingAmounts += totalDepositsAmount;
        vaultData.totalAssets = totalAssets + totalDepositsAmount;

        if (processCount + index == queueLength) {
            VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.NotTraded);
        }
    }

    function addToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy
    ) internal {
        Vault storage vaultData = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vaultData.productId];

        require(
            sharesAmount >= dcsProduct.minWithdrawalAmount,
            Errors.VALUE_TOO_SMALL
        );
        require(nextProductId == 0 || !useProxy, Errors.NO_PROXY_FOR_REDEPOSIT);

        ICegaVault(vaultAddress).transferFrom(
            msg.sender,
            vaultAddress,
            sharesAmount
        );

        WithdrawalQueue storage queue = cgs.dcsWithdrawalQueues[vaultAddress];
        uint256 currentQueuedAmount = queue.amounts[msg.sender][nextProductId];
        if (currentQueuedAmount == 0) {
            queue.withdrawers.push(
                Withdrawer({
                    account: msg.sender,
                    nextProductId: nextProductId
                })
            );
        }
        queue.amounts[msg.sender][nextProductId] =
            currentQueuedAmount +
            sharesAmount;
        queue.withdrawingWithProxy[msg.sender] = useProxy;

        queue.queuedWithdrawalSharesAmount += sharesAmount;

        emit WithdrawalQueued(
            vaultAddress,
            sharesAmount,
            msg.sender,
            nextProductId,
            useProxy
        );
    }

    function processWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        uint256 maxProcessCount
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 processCount)
    {
        require(
            VaultLogic.isWithdrawalPossible(cgs, vaultAddress),
            Errors.INVALID_VAULT_STATUS
        );

        Vault storage vaultData = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        address settlementAsset = getVaultSettlementAsset(cgs, vaultAddress);
        uint128 totalAssets = vaultData.totalAssets;
        uint256 totalSupply = ICegaVault(vaultAddress).totalSupply();
        address wrappingProxy = addressManager.getAssetWrappingProxy(
            settlementAsset
        );

        WithdrawalQueue storage queue = cgs.dcsWithdrawalQueues[vaultAddress];
        uint256 queueLength = queue.withdrawers.length;
        uint256 index = queue.processedIndex;
        processCount = maxProcessCount == 0
            ? queueLength - index
            : Math.min(queueLength - index, maxProcessCount);
        uint256 totalSharesWithdrawn;
        uint128 totalAssetsWithdrawn;

        for (uint256 i = 0; i < processCount; i++) {
            (uint256 sharesAmount, uint128 assetAmount) = processWithdrawal(
                queue,
                treasury,
                addressManager,
                vaultAddress,
                index + i,
                settlementAsset,
                totalAssets,
                totalSupply,
                wrappingProxy
            );
            totalSharesWithdrawn += sharesAmount;
            totalAssetsWithdrawn += assetAmount;
        }

        ICegaVault(vaultAddress).burn(vaultAddress, totalSharesWithdrawn);
        queue.queuedWithdrawalSharesAmount -= totalSharesWithdrawn.toUint128();
        queue.processedIndex += processCount.toUint128();
        vaultData.totalAssets -= totalAssetsWithdrawn;

        if (
            cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset ||
            dcsVault.settlementStatus == SettlementStatus.Defaulted
        ) {
            cgs
                .dcsProducts[vaultData.productId]
                .sumVaultUnderlyingAmounts -= totalAssetsWithdrawn;
        }

        if (index + processCount == queueLength) {
            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.WithdrawalQueueProcessed
            );
        }
    }

    function processWithdrawal(
        WithdrawalQueue storage queue,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        uint256 index,
        address settlementAsset,
        uint128 totalAssets,
        uint256 totalSupply,
        address wrappingProxy
    ) private returns (uint256 sharesAmount, uint128 assetAmount) {
        Withdrawer memory withdrawer = queue.withdrawers[index];
        sharesAmount = queue.amounts[withdrawer.account][
            withdrawer.nextProductId
        ];

        assetAmount = VaultLogic.convertToAssets(
            totalSupply,
            totalAssets,
            sharesAmount
        );

        if (withdrawer.nextProductId == 0) {
            if (
                wrappingProxy != address(0) &&
                queue.withdrawingWithProxy[withdrawer.account]
            ) {
                treasury.withdraw(
                    settlementAsset,
                    wrappingProxy,
                    assetAmount,
                    true
                );
                IWrappingProxy(wrappingProxy).unwrapAndTransfer(
                    withdrawer.account,
                    assetAmount
                );
            } else {
                treasury.withdraw(
                    settlementAsset,
                    withdrawer.account,
                    assetAmount,
                    false
                );
            }
        } else {
            redeposit(
                treasury,
                addressManager,
                settlementAsset,
                assetAmount,
                withdrawer.account,
                withdrawer.nextProductId
            );
        }

        emit WithdrawalProcessed(
            vaultAddress,
            sharesAmount,
            withdrawer.account,
            withdrawer.nextProductId
        );

        delete queue.amounts[withdrawer.account][withdrawer.nextProductId];
    }

    function redeposit(
        ITreasury treasury,
        IAddressManager addressManager,
        address asset,
        uint128 amount,
        address owner,
        uint32 nextProductId
    ) private {
        address redepositManager = addressManager.getRedepositManager();
        IRedepositManager(redepositManager).redeposit(
            treasury,
            nextProductId,
            asset,
            amount,
            owner
        );
    }

    function checkTradeExpiry(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        SettlementStatus settlementStatus = dcsVault.settlementStatus;
        VaultStatus vaultStatus = vault.vaultStatus;
        require(
            settlementStatus == SettlementStatus.InitialPremiumPaid ||
                settlementStatus == SettlementStatus.AwaitingSettlement,
            Errors.INVALID_SETTLEMENT_STATUS
        );
        require(
            vaultStatus == VaultStatus.Traded ||
                vaultStatus == VaultStatus.TradeExpired,
            Errors.INVALID_VAULT_STATUS
        );
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        uint40 tenorInSeconds = dcsProduct.tenorInSeconds;
        uint40 tradeStartDate = vault.tradeStartDate;

        uint256 currentTime = block.timestamp;
        if (currentTime <= tradeStartDate + tenorInSeconds) {
            return;
        }
        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.TradeExpired);

        uint128 finalSpotPrice = getSpotPriceAt(
            cgs,
            vaultAddress,
            addressManager,
            tradeStartDate + tenorInSeconds
        );

        if (
            isSwapOccurring(
                finalSpotPrice,
                dcsVault.strikePrice,
                dcsProduct.dcsOptionType
            )
        ) {
            VaultLogic.setIsPayoffInDepositAsset(cgs, vaultAddress, false);

            VaultLogic.setVaultSettlementStatus(
                cgs,
                vaultAddress,
                SettlementStatus.AwaitingSettlement
            );
        } else {
            VaultLogic.setVaultSettlementStatus(
                cgs,
                vaultAddress,
                SettlementStatus.Settled
            );
        }
    }

    function checkSettlementDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint256 daysLate = VaultLogic.getDaysLate(
            vault.tradeStartDate + dcsProduct.tenorInSeconds
        );
        if (
            daysLate >= dcsProduct.daysToStartSettlementDefault &&
            dcsVault.settlementStatus == SettlementStatus.AwaitingSettlement
        ) {
            VaultLogic.setVaultSettlementStatus(
                cgs,
                vaultAddress,
                SettlementStatus.Defaulted
            );
        }
    }

    /// @notice Starts trade
    /// @param cgs Cega Global Storage
    /// @param vaultAddress Address of the vault to trade
    /// @param tradeWinnerNFT Address of the NFT to mint (0 to skip minting)
    function startTrade(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        address tradeWinnerNFT,
        ITreasury treasury,
        IAddressManager addressManager
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 nativeValueReceived, MMNFTMetadata memory nftMetadata)
    {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        uint40 tenorInSeconds = dcsProduct.tenorInSeconds;

        require(msg.sender == vault.auctionWinner, Errors.NOT_TRADE_WINNER);
        require(
            dcsVault.settlementStatus == SettlementStatus.Auctioned,
            Errors.INVALID_SETTLEMENT_STATUS
        );
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        require(
            block.timestamp >= vault.tradeStartDate,
            Errors.TRADE_NOT_STARTED
        );
        require(
            !VaultLogic.getIsDefaulted(cgs, vaultAddress),
            Errors.TRADE_DEFAULTED
        );

        // Transfer the premium + any applicable late fee
        uint40 tradeStartDate = vault.tradeStartDate;
        address depositAsset = dcsGetProductDepositAsset(dcsProduct);
        uint128 totalAssets = vault.totalAssets;
        uint16 aprBps = dcsVault.aprBps;

        nftMetadata = MMNFTMetadata({
            vaultAddress: vaultAddress,
            tradeStartDate: tradeStartDate,
            tradeEndDate: tradeStartDate + tenorInSeconds,
            notional: totalAssets,
            aprBps: aprBps,
            initialSpotPrice: dcsVault.initialSpotPrice,
            strikePrice: dcsVault.strikePrice
        });

        uint128 totalYield = VaultLogic.calculateCouponPayment(
            totalAssets,
            tradeStartDate,
            tenorInSeconds,
            aprBps,
            tradeStartDate + tenorInSeconds
        );
        dcsVault.totalYield = totalYield;
        uint128 lateFee = VaultLogic.calculateLateFee(
            totalYield,
            tradeStartDate,
            dcsProduct.lateFeeBps,
            dcsProduct.daysToStartLateFees,
            dcsProduct.daysToStartAuctionDefault
        );
        // Send deposit to treasury, and late fee to fee recipient
        nativeValueReceived = depositAsset.receiveTo(
            addressManager.getCegaFeeReceiver(),
            lateFee
        );
        nativeValueReceived += depositAsset.receiveTo(
            address(treasury),
            totalYield
        );
        // Late fee is not used for coupon payment or for user payouts
        uint128 notionalAmount = vault.totalAssets;
        vault.totalAssets = notionalAmount + totalYield;
        dcsProduct.sumVaultUnderlyingAmounts += totalYield;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Traded);
        VaultLogic.setVaultSettlementStatus(
            cgs,
            vaultAddress,
            SettlementStatus.InitialPremiumPaid
        );

        if (tradeWinnerNFT != address(0)) {
            uint256 tokenId = ITradeWinnerNFT(tradeWinnerNFT).mint(
                msg.sender,
                nftMetadata
            );
            vault.auctionWinnerTokenId = tokenId.toUint64();
        }

        emit DCSTradeStarted(
            vaultAddress,
            msg.sender,
            notionalAmount,
            totalYield
        );
    }

    function checkAuctionDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        bool isDefaulted = VaultLogic.getIsDefaulted(cgs, vaultAddress);
        if (isDefaulted) {
            VaultLogic.setVaultSettlementStatus(
                cgs,
                vaultAddress,
                SettlementStatus.Defaulted
            );
        }
    }

    function settleVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        ITreasury treasury,
        IAddressManager addressManager
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 nativeValueReceived)
    {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        {
            uint256 auctionWinnerTokenId = vault.auctionWinnerTokenId;

            require(auctionWinnerTokenId != 0, Errors.TRADE_HAS_NO_WINNER);
            require(
                msg.sender ==
                    IERC721AUpgradeable(addressManager.getTradeWinnerNFT())
                        .ownerOf(auctionWinnerTokenId),
                Errors.NOT_TRADE_WINNER
            );
        }
        require(
            dcsVault.isPayoffInDepositAsset == false,
            Errors.TRADE_NOT_CONVERTED
        );

        checkSettlementDefault(cgs, vaultAddress);

        require(
            dcsVault.settlementStatus == SettlementStatus.AwaitingSettlement,
            Errors.INVALID_SETTLEMENT_STATUS
        );

        (
            address depositAsset,
            address swapAsset,
            DCSOptionType dcsOptionType
        ) = getDCSProductDepositAndSwapAsset(dcsProduct);

        // First, store the totalAssets and totalYield in depositAsset units
        uint128 depositTotalAssets = vault.totalAssets;
        uint128 depositTotalYield = dcsVault.totalYield;
        uint128 strikePrice = dcsVault.strikePrice;
        uint8 depositAssetDecimals = VaultLogic.getAssetDecimals(depositAsset);
        uint8 swapAssetDecimals = VaultLogic.getAssetDecimals(swapAsset);

        // Then, calculate the totalAssets and totalYield in swapAsset units
        uint128 convertedTotalAssets = convertDepositUnitsToSwap(
            depositTotalAssets,
            addressManager,
            strikePrice,
            depositAssetDecimals,
            swapAssetDecimals,
            dcsOptionType
        );
        uint128 convertedTotalYield = convertDepositUnitsToSwap(
            depositTotalYield,
            addressManager,
            strikePrice,
            depositAssetDecimals,
            swapAssetDecimals,
            dcsOptionType
        );

        // Then, update state. Store the new converted amounts of totalAssets and totalYield
        // and subtract assets from sumVaultUnderlyingAmounts. We've converted, so this vault
        // no longer applies to sumVaultUnderlyingAmounts
        dcsProduct.sumVaultUnderlyingAmounts -= depositTotalAssets;
        vault.totalAssets = convertedTotalAssets;
        dcsVault.totalYield = convertedTotalYield;

        VaultLogic.setVaultSettlementStatus(
            cgs,
            vaultAddress,
            SettlementStatus.Settled
        );

        // After converting units, we actually transfer the depositAsset to nftHolder and receive swapAsset from nftHolder
        treasury.withdraw(depositAsset, msg.sender, depositTotalAssets, false);
        nativeValueReceived = swapAsset.receiveTo(
            address(treasury),
            convertedTotalAssets
        );

        emit DCSVaultSettled(
            vaultAddress,
            msg.sender,
            convertedTotalAssets,
            depositTotalAssets
        );
    }

    function collectVaultFees(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        require(
            vault.vaultStatus == VaultStatus.TradeExpired,
            Errors.INVALID_VAULT_STATUS
        );
        SettlementStatus settlementStatus = dcsVault.settlementStatus;
        require(
            settlementStatus == SettlementStatus.Settled ||
                settlementStatus == SettlementStatus.Defaulted,
            Errors.INVALID_SETTLEMENT_STATUS
        );

        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);

        (
            uint128 totalFees,
            uint128 managementFee,
            uint128 yieldFee
        ) = VaultLogic.calculateFees(cgs, vaultAddress);
        address settlementAsset = getVaultSettlementAsset(cgs, vaultAddress);

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.FeesCollected);
        vault.totalAssets -= totalFees;

        treasury.withdraw(
            settlementAsset,
            addressManager.getCegaFeeReceiver(),
            totalFees,
            true
        );

        if (
            dcsVault.isPayoffInDepositAsset ||
            settlementStatus == SettlementStatus.Defaulted
        ) {
            dcsProduct.sumVaultUnderlyingAmounts -= uint128(totalFees);
        }

        emit DCSVaultFeesCollected(
            vaultAddress,
            totalFees,
            managementFee,
            yieldFee
        );
    }
}
