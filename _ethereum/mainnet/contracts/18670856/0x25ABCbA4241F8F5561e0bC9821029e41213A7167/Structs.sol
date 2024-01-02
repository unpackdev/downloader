// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./DCSStructs.sol";
import "./IOracleEntry.sol";

uint32 constant DCS_STRATEGY_ID = 1;

struct DepositQueue {
    uint128 queuedDepositsTotalAmount;
    uint128 processedIndex;
    mapping(address => uint128) amounts;
    address[] depositors;
}

struct Withdrawer {
    address account;
    uint32 nextProductId;
}

struct ProductMetadata {
    string name;
    string tradeWinnerNftImage;
}

struct WithdrawalQueue {
    uint128 queuedWithdrawalSharesAmount;
    uint128 processedIndex;
    mapping(address => mapping(uint32 => uint256)) amounts;
    Withdrawer[] withdrawers;
    mapping(address => bool) withdrawingWithProxy;
}

struct CegaGlobalStorage {
    // Global information
    uint32 strategyIdCounter;
    uint32 productIdCounter;
    uint32[] strategyIds;
    mapping(uint32 => uint32) strategyOfProduct;
    mapping(uint32 => ProductMetadata) productMetadata;
    mapping(address => Vault) vaults;
    // DCS information
    mapping(uint32 => DCSProduct) dcsProducts;
    mapping(uint32 => DepositQueue) dcsDepositQueues;
    mapping(address => DCSVault) dcsVaults;
    mapping(address => WithdrawalQueue) dcsWithdrawalQueues;
    // vaultAddress => (timestamp => price)
    mapping(address => mapping(uint40 => uint128)) oraclePriceOverride;
}

struct Vault {
    uint128 totalAssets;
    uint64 auctionWinnerTokenId;
    uint16 yieldFeeBps;
    uint16 managementFeeBps;
    uint32 productId;
    address auctionWinner;
    uint40 tradeStartDate;
    VaultStatus vaultStatus;
    IOracleEntry.DataSource dataSource;
    bool isInDispute;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct MMNFTMetadata {
    address vaultAddress;
    uint40 tradeStartDate;
    uint40 tradeEndDate;
    uint16 aprBps;
    uint128 notional;
    uint128 initialSpotPrice;
    uint128 strikePrice;
}
