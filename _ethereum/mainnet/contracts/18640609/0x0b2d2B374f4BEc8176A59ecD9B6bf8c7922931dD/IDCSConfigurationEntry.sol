// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDCSConfigurationEntry {
    // FUNCTIONS

    function dcsSetLateFeeBps(uint16 lateFeeBps, uint32 productId) external;

    function dcsSetMinDepositAmount(
        uint128 minDepositAmount,
        uint32 productId
    ) external;

    function dcsSetMinWithdrawalAmount(
        uint128 minWithdrawalAmount,
        uint32 productId
    ) external;

    function dcsSetIsDepositQueueOpen(
        bool isDepositQueueOpen,
        uint32 productId
    ) external;

    function dcsSetDaysToStartLateFees(
        uint32 productId,
        uint8 daysToStartLateFees
    ) external;

    function dcsSetDaysToStartAuctionDefault(
        uint32 productId,
        uint8 daysToStartAuctionDefault
    ) external;

    function dcsSetDaysToStartSettlementDefault(
        uint32 productId,
        uint8 daysToStartSettlementDefault
    ) external;

    function dcsSetMaxUnderlyingAmount(
        uint128 maxUnderlyingAmountLimit,
        uint32 productId
    ) external;

    function dcsSetManagementFee(address vaultAddress, uint16 value) external;

    function dcsSetYieldFee(address vaultAddress, uint16 value) external;

    function dcsSetDisputePeriodInHours(
        uint32 productId,
        uint8 disputePeriodInHours
    ) external;

    function setProductName(uint32 productId, string memory name) external;

    function setTradeWinnerNftImage(
        uint32 productId,
        string memory imageUrl
    ) external;
}
