// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./Vault.sol";

abstract contract RibbonEarnVaultStorageV1 {
    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the allocation between lending and buying options
    Vault.AllocationState public allocationState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNextRound and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice borrower is the address of the borrowing entity (EX: Wintermute, GSR, Alameda, Genesis)
    address public borrower;

    /// @notice pendingBorrower is the pending address of the borrowing entity (EX: Wintermute, GSR, Alameda, Genesis)
    address public pendingBorrower;

    /// @notice lastBorrowerChange is the last time borrower was set
    uint256 public lastBorrowerChange;

    /// @notice optionSeller is the address of the entity that we will be buying options from (EX: Orbit)
    address public optionSeller;

    /// @notice pendingOptionSeller is the pending address of the entity that we will be buying options from (EX: Orbit)
    address public pendingOptionSeller;

    /// @notice lastOptionSellerChange is the last time option seller was set
    uint256 public lastOptionSellerChange;

    /// @notice Performance fee charged on premiums earned in rollToNextRound. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextRound. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;

    /// @notice Queued withdraw shares for the current round
    uint256 public currentQueuedWithdrawShares;

    /// @notice Vault Pauser Contract for the vault
    address public vaultPauser;

    /// @notice LiquidityGauge contract for the vault
    address public liquidityGauge;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of RibbonEarnVaultStorage
// e.g. RibbonEarnVaultStorage<versionNumber>, so finally it would look like
// contract RibbonEarnVaultStorage is RibbonEarnVaultStorageV1, RibbonEarnVaultStorageV2
abstract contract RibbonEarnVaultStorage is RibbonEarnVaultStorageV1 {

}
