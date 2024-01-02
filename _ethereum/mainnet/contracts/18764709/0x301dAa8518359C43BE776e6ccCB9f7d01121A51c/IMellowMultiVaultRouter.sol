// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./IWETH.sol";
import "./IERC20RootVault.sol";

interface IMellowMultiVaultRouter {
    struct BatchedDeposit {
        address author;
        uint256 amount;
    }

    struct BatchedDeposits {
        mapping(uint256 => BatchedDeposit) batch;
        uint256 current;
        uint256 size;
    }

    struct BatchedAutoRollover {
        uint256 fromVault;
        uint256 lpTokensAutoRolledOver;
    }

    struct BatchedAutoRollovers {
        mapping(uint256 => BatchedAutoRollover) batch;
        uint256 current;
        uint256 size;
    }

    // -------------------  INITIALIZER -------------------

    /// @notice Constructor for Proxies
    function initialize(
        IWETH weth_,
        IERC20Minimal token_,
        IERC20RootVault[] memory vaults_
    ) external;

    // -------------------  GETTERS -------------------

    /// @notice The official WETH of the network
    function weth() external view returns (IWETH);

    /// @notice The underlying token of the vaults
    function token() external view returns (IERC20Minimal);

    /// @notice Active batched deposits
    function getBatchedDeposits(uint256 index)
        external
        view
        returns (BatchedDeposit[] memory);

    /// @notice Get the LP token balances
    function getLPTokenBalances(address owner)
        external
        view
        returns (uint256[] memory);

    /// @notice Get the active optimiser indices
    function getActiveIndices(address owner)
        external
        view
        returns (uint256[] memory activeIndices);

    /// @notice All vaults assigned to this router
    function getVaults() external view returns (IERC20RootVault[] memory);

    /// @notice Checks if the vault is completed
    function isVaultCompleted(uint256 index) external view returns (bool);

    /// @notice Checks if the vault is paused
    function isVaultPaused(uint256 index) external view returns (bool);

    function getVaultMaturity(uint256 vaultIndex)
        external
        view
        returns (uint256);

    function getCachedVaultMaturity(uint256 vaultIndex)
        external
        returns (uint256);

    /// @notice Fee paid for router deposit
    function getFee() external view returns (uint256);

    /// @notice Returns fee accumulated
    function getTotalFee() external view returns (uint256);

    /// @notice Returns number of pending vault deposits
    function getVaultDepositsCount() external view returns (uint256);

    // -------------------  CHECKS  -------------------

    function validWeights(uint256[] memory weights)
        external
        view
        returns (bool);

    function canWithdrawOrRollover(uint256 vaultIndex, address owner)
        external
        view
        returns (bool);

    // -------------------  SETTERS  -------------------

    /// @notice Add another vault to the router
    /// @param vault_ The new vault
    function addVault(IERC20RootVault vault_) external;

    /// @notice Mark vault as completed/uncompleted
    /// @param index The index of the vault to set completion for
    function setCompletion(uint256 index, bool completed) external;

    /// @notice Pause/unpause vault
    /// @param index The index of the vault to set pausability for
    function setPausability(uint256 index, bool paused) external;

    /// @notice Set fee for each router deposit
    /// @param fee_ Desired fee in underlying token
    function setFee(uint256 fee_) external;

    /// @notice Update number of vault deposits
    function refreshDepositCount() external;

    // -------------------  DEPOSITS  -------------------

    /// @notice Deposit ETH to the router
    function depositEth(uint256[] memory weights) external payable;

    /// @notice Deposit ERC20 to the router
    function depositErc20(uint256 amount, uint256[] memory weights) external;

    /// @notice Deposit ETH to the router and registers for auto-rollover
    function depositEthAndRegisterForAutoRollover(
        uint256[] memory weights,
        bool registration
    ) external payable;

    /// @notice Deposit ERC20 to the router and registers for auto-rollover
    function depositErc20AndRegisterForAutoRollover(
        uint256 amount,
        uint256[] memory weights,
        bool registration
    ) external;

    // -------------------  BATCH PUSH  -------------------

    /// @notice Push the batched funds of all vaults to Mellow
    /// and transfer deserving fee to sender
    function submitAllBatchesForFee() external;

    /// @notice Push the batched funds of specified vault to Mellow
    /// and transfer deserving fee to sender
    function submitBatchForFee(
        uint256 index,
        uint256 batchSize,
        address account
    ) external;

    /// @notice Push the batched funds to Mellow
    function submitBatch(uint256 index, uint256 batchSize) external;

    // -------------------  WITHDRAWALS  -------------------

    /// @notice Burn the lp tokens and withdraw the funds
    function claimLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions
    ) external;

    /// @notice Burn the lp tokens and rollover the funds according to the weights
    function rolloverLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions,
        uint256[] memory weights
    ) external;

    // -------------------  AUTO-ROLLOVERS  -------------------
    /// @notice Allow users to opt into and out of auto-rollover functionality
    function registerForAutoRollover(bool registration) external;

    /// @notice Roll over user funds from expired (completed) vault into new vaults
    function triggerAutoRollover(uint256 vaultIndex) external;

    function setAutoRolloverWeights(uint256[] memory autoRolloverWeights)
        external;

    // AUTO-ROLLOVER GETTERS

    /// @notice Total LP Tokens to be auto-rolled over for given vault
    function totalAutoRolloverLPTokens(uint256 vaultIndex)
        external
        view
        returns (uint256);

    function isRegisteredForAutoRollover(address owner)
        external
        view
        returns (bool);

    /// @notice Batched auto-rollover deposits for given vault
    function getBatchedAutoRollovers(uint256 index)
        external
        view
        returns (BatchedAutoRollover[] memory);

    function getAutoRolloverWeights() external view returns (uint256[] memory);

    function getAutoRolledOverVaults() external view returns (uint256[] memory);

    function getPendingAutoRolloverDeposits(uint256 vaultIndex)
        external
        view
        returns (uint256);

    /// @notice Auto-rollover exchange rate between fromVault and toVault
    function getAutoRolloverExchangeRatesWad(uint256 fromVault, uint256 toVault)
        external
        view
        returns (uint256);

    function getPropagatedAutoRolloverLPTokens(address owner)
        external
        view
        returns (uint256[] memory);
}
