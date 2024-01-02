// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import "./draft-IERC20Permit.sol";
import "./IERC4626.sol";
import "./IMigratable.sol";

/**
 * @title IVault
 * @notice Interface contract for Pods Vault
 * @author Pods Finance
 */
interface IVault is IERC4626, IERC20Permit, IMigratable {
    error IVault__CallerIsNotTheController();
    error IVault__NotProcessingDeposits();
    error IVault__AlreadyProcessingDeposits();
    error IVault__ForbiddenWhileProcessingDeposits();
    error IVault__ZeroAssets();
    error IVault__AssetsUnderMinimumAmount(uint256 assets);
    error IVault__WithdrawNotRequested();
    error IVault__WithdrawNotFound(address owner);
    error IVault__WithdrawRequestAboveMax(address caller, address owner, uint256 assets, uint256 maxAssets);
    error IVault__AlreadyInExpiredMode();

    event FeeCollected(uint256 fee);
    event RoundStarted(uint32 indexed roundId, uint256 amountAddedToStrategy);
    event RoundEnded(uint32 indexed roundId);
    event DepositProcessed(address indexed owner, uint32 indexed roundId, uint256 assets, uint256 shares);
    event DepositRefunded(address indexed owner, uint32 indexed roundId, uint256 assets);
    event Migrated(address indexed caller, address indexed from, address indexed to, uint256 assets, uint256 shares);
    event WithdrawRequested(
        uint256 indexed roundId,
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event WithdrawFeeRatioChanged(uint16 newWithdrawFeeRatio);
    event WithdrawDisbursed(address indexed owner, uint256 assets, uint256 shares);
    event VaultExpired();

    /**
     * @dev Describes the vault state variables.
     */
    struct VaultState {
        uint256 processedDeposits;
        uint256 pendingDeposits;
        uint256 pendingWithdrawals;
        uint32 currentRoundId;
        uint40 lastEndRoundTimestamp;
        uint16 withdrawFeeRatio;
        bool isProcessingDeposits;
        bool isExpired;
    }

    struct Fractional {
        uint256 numerator;
        uint256 denominator;
    }

    /**
     * @notice Returns the current round ID.
     */
    function currentRoundId() external view returns (uint32);

    /**
     * @notice Determines whether the Vault is in the processing deposits state.
     * @dev While it's processing deposits, `processDeposits` can be called and new shares can be created.
     * During this period deposits, mints, withdraws and redeems are blocked.
     */
    function isProcessingDeposits() external view returns (bool);

    /**
     * @notice Determines whether the Vault is in expired mode.
     */
    function isExpired() external view returns (bool);

    /**
     * @notice Returns the amount of processed deposits entering the next round.
     */
    function processedDeposits() external view returns (uint256);

    /**
     * @notice Returns the fee charged on withdraws.
     */
    function getWithdrawFeeRatio() external view returns (uint256);

    /**
     * @notice Sets the fee charged on withdraws.
     */
    function setWithdrawFeeRatio(uint16 newWithdrawFeeRatio) external;

    /**
     * @notice Returns the vault controller
     */
    function controller() external view returns (address);

    /**
     * @notice Outputs the amount of asset tokens of an `owner` is idle, waiting for the next round.
     */
    function pendingDepositsOf(address owner) external view returns (uint256);

    /**
     * @notice Outputs the amount of asset tokens that an `owner` has waiting to withdraw.
     */
    function pendingWithdrawOf(address owner) external view returns (uint256);

    /**
     * @notice Outputs the amount of asset tokens of an `owner` are either waiting for the next round,
     * deposited or committed.
     */
    function assetsOf(address owner) external view returns (uint256);

    /**
     * @notice Outputs the amount of asset tokens is idle, waiting for the next round.
     */
    function totalPendingDeposits() external view returns (uint256);

    /**
     * @notice Outputs the amount of asset tokens are pending to be withdrawal.
     */
    function totalPendingWithdrawals() external view returns (uint256);

    /**
     * @notice Outputs current size of the deposit queue.
     */
    function depositQueueSize() external view returns (uint256);

    /**
     * @notice Outputs current size of the withdraw queue.
     */
    function withdrawQueueSize() external view returns (uint256);

    /**
     * @notice Outputs addresses in the deposit queue
     */
    function queuedDeposits() external view returns (address[] memory);

    /**
     * @notice Outputs addresses in the withdraw queue
     */
    function queuedWithdrawals() external view returns (address[] memory);

    /**
     * @notice Deposit ERC20 tokens with permit, a gasless token approval.
     * @dev Mints shares to receiver by depositing exactly amount of underlying tokens.
     *
     * For more information on the signature format, see the EIP2612 specification:
     * https://eips.ethereum.org/EIPS/eip-2612#specification
     */
    function depositWithPermit(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    /**
     * @notice Mint shares with permit, a gasless token approval.
     * @dev Mints exactly shares to receiver by depositing amount of underlying tokens.
     *
     * For more information on the signature format, see the EIP2612 specification:
     * https://eips.ethereum.org/EIPS/eip-2612#specification
     */
    function mintWithPermit(
        uint256 shares,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    /**
     * @notice Initiates the redeem process by recording the requested redeem shares.
     *
     * @dev This function handles the initial redeem request. The actual redeem should be
     * handled by `redeem` function. It should check if the redeem is valid, convert the
     * requested share amount to assets, and record the redeem information for later processing.
     */
    function requestRedeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    /**
     * @notice Initiates the withdrawal process by recording the requested withdrawal assets.
     *
     * @dev This function handles the initial withdrawal request. The actual withdrawal should be
     * handled by `withdraw` function. It should check if the withdrawal is valid, convert the
     * requested asset amount to shares, and record the withdrawal information for later processing.
     */
    function requestWithdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @notice Transition the vault to a Expired Mode
     * @dev The expired mode is a state where deposits are not allowed and withdraws can be done without
     * requesting it.
     */
    function setExpiredMode() external;

    /**
     * @notice Starts the next round, sending the idle funds to the
     * strategy where it should start accruing yield.
     * @param data Custom data to be processed
     * @return The new round id
     */
    function startRound(bytes calldata data) external returns (uint32);

    /**
     * @notice Closes the round, allowing deposits to the next round be processed.
     * and opens the window for withdraws.
     * @param data Custom data to be processed
     */
    function endRound(bytes calldata data) external;

    /**
     * @notice This function sends the disbursement of withdrawals based on the provided receipt IDs.
     * @param depositors An array of addresses of share owners be withdrawn.
     */
    function disburseWithdrawals(address[] calldata depositors) external;

    /**
     * @notice Withdraw all user assets in unprocessed deposits.
     */
    function refund() external returns (uint256 assets);

    /**
     * @notice Migrate assets from this vault to the next vault.
     * @dev The `newVault` will be assigned by the ConfigurationManager
     */
    function migrate() external;

    /**
     * @notice Handle migrated assets.
     * @return Estimation of shares created.
     */
    function handleMigration(uint256 assets, address receiver) external returns (uint256);

    /**
     * @notice Distribute shares to depositors queued in the deposit queue, effectively including their assets in the next round.
     *
     * @param depositors Array of owner addresses to process
     */
    function processQueuedDeposits(address[] calldata depositors) external;
}
