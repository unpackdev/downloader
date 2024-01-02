// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Structs.sol";
import "./DCSStructs.sol";
import "./IDCSProductEntry.sol";
import "./IDCSVaultEntry.sol";
import "./IDCSConfigurationEntry.sol";
import "./IDCSBulkActionsEntry.sol";
import "./IProductViewEntry.sol";
import "./IVaultViewEntry.sol";

interface IDCSEntry is
    IDCSProductEntry,
    IDCSVaultEntry,
    IDCSConfigurationEntry,
    IDCSBulkActionsEntry,
    IProductViewEntry,
    IVaultViewEntry
{
    // EVENTS

    event DCSProductCreated(uint32 indexed productId);

    event DepositQueued(
        uint32 indexed productId,
        address sender,
        address receiver,
        uint128 amount
    );

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

    event VaultStatusUpdated(
        address indexed vaultAddress,
        VaultStatus vaultStatus
    );

    event DCSSettlementStatusUpdated(
        address indexed vaultAddress,
        SettlementStatus settlementStatus
    );

    event DCSVaultFeesCollected(
        address indexed vaultAddress,
        uint128 totalFees,
        uint128 managementFee,
        uint128 yieldFee
    );

    event VaultCreated(
        uint32 indexed productId,
        address indexed vaultAddress,
        string _tokenSymbol,
        string _tokenName
    );

    event DCSAuctionEnded(
        address indexed vaultAddress,
        address indexed auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        uint128 initialSpotPrice,
        uint128 strikePrice
    );

    event DCSTradeStarted(
        address indexed vaultAddress,
        address auctionWinner,
        uint128 notionalAmount,
        uint128 yieldAmount
    );

    event DCSVaultSettled(
        address indexed vaultAddress,
        address settler,
        uint128 depositedAmount,
        uint128 withdrawnAmount
    );

    event DCSVaultRolledOver(address indexed vaultAddress);

    event DCSIsPayoffInDepositAssetUpdated(
        address indexed vaultAddress,
        bool isPayoffInDepositAsset
    );

    event DCSLateFeeBpsUpdated(uint32 indexed productId, uint16 lateFeeBps);

    event DCSMinDepositAmountUpdated(
        uint32 indexed productId,
        uint128 minDepositAmount
    );

    event DCSMinWithdrawalAmountUpdated(
        uint32 indexed productId,
        uint128 minWithdrawalAmount
    );

    event DCSIsDepositQueueOpenUpdated(
        uint32 indexed productId,
        bool isDepositQueueOpen
    );

    event DCSMaxUnderlyingAmountLimitUpdated(
        uint32 indexed productId,
        uint128 maxUnderlyingAmountLimit
    );

    event DCSManagementFeeUpdated(address indexed vaultAddress, uint16 value);

    event DCSYieldFeeUpdated(address indexed vaultAddress, uint16 value);

    event DisputeSubmitted(address indexed vaultAddress);

    event DCSDisputePeriodInHoursUpdated(
        uint32 indexed productId,
        uint8 disputePeriodInHours
    );

    event DCSDaysToStartLateFeesUpdated(
        uint32 indexed productId,
        uint8 daysToStartLateFees
    );

    event DCSDaysToStartAuctionDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartAuctionDefault
    );

    event DCSDaysToStartSettlementDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartSettlementDefault
    );

    event ProductNameUpdated(uint32 indexed productId, string name);
    event TradeWinnerNftImageUpdated(uint32 indexed productId, string imageUrl);
}
