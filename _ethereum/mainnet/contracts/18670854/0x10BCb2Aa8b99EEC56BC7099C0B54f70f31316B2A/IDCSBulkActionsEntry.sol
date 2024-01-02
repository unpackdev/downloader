// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./Structs.sol";
import "./DCSStructs.sol";
import "./IOracleEntry.sol";

interface IDCSBulkActionsEntry {
    // FUNCTIONS

    function dcsBulkStartTrades(
        address[] calldata vaultAddresses
    ) external payable;

    function dcsBulkOpenVaultDeposits(
        address[] calldata vaultAddresses
    ) external;

    function dcsBulkProcessDepositQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    function dcsBulkProcessWithdrawalQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    function dcsBulkRolloverVaults(address[] calldata vaultAddresses) external;

    function dcsBulkCheckTradesExpiry(
        address[] calldata vaultAddresses
    ) external;

    function dcsBulkCheckAuctionDefault(
        address[] calldata vaultAddresses
    ) external;

    function dcsBulkCheckSettlementDefault(
        address[] calldata vaultAddresses
    ) external;

    function dcsBulkSettleVaults(
        address[] calldata vaultAddresses
    ) external payable;

    function dcsBulkCollectFees(address[] calldata vaultAddresses) external;
}
