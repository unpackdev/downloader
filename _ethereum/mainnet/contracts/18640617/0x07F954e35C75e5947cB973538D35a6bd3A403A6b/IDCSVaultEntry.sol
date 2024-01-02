// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Structs.sol";
import "./DCSStructs.sol";
import "./IOracleEntry.sol";

interface IDCSVaultEntry {
    // FUNCTIONS

    function dcsGetVault(
        address vaultAddress
    ) external view returns (DCSVault memory);

    function dcsCalculateLateFee(
        address vaultAddress
    ) external view returns (uint128);

    function dcsGetCouponPayment(
        address vaultAddress
    ) external view returns (uint128);

    function openVaultDeposits(address vaultAddress) external;

    function setVaultStatus(
        address vaultAddress,
        VaultStatus _vaultStatus
    ) external;

    function dcsCreateVault(
        uint32 productId,
        string memory _tokenName,
        string memory _tokenSymbol
    ) external returns (address vaultAddress);

    function dcsEndAuction(
        address vaultAddress,
        address _auctionWinner,
        uint40 _tradeStartDate,
        uint16 _aprBps,
        IOracleEntry.DataSource dataSource
    ) external;

    function dcsStartTrade(address vaultAddress) external payable;

    function dcsSettleVault(address vaultAddress) external payable;

    function dcsRolloverVault(address vaultAddress) external;

    function dcsSetSettlementStatus(
        address vaultAddress,
        SettlementStatus _settlementStatus
    ) external;

    function dcsSetIsPayoffInDepositAsset(
        address vaultAddress,
        bool newState
    ) external;

    function dcsCheckAuctionDefault(address vaultAddress) external;

    function overrideOraclePrice(
        address vaultAddress,
        uint40 timestamp,
        uint128 newPrice
    ) external;
}
