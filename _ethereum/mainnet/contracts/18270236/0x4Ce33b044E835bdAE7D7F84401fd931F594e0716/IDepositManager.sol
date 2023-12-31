// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ISmartVault.sol";
import "./uint16a16Lib.sol";

/**
 * @notice Used when deposited assets are not the same length as underlying assets.
 */
error InvalidAssetLengths();

/**
 * @notice Used when lengths of NFT id and amount arrays when claiming NFTs don't match.
 */
error InvalidNftArrayLength();

/**
 * @notice Used when there are no pending deposits to recover.
 * E.g., they were already recovered or flushed.
 */
error NoDepositsToRecover();

/**
 * @notice Used when trying to recover pending deposits from a smart vault that has non-ghost strategies.
 */
error NotGhostVault();

/**
 * @notice Gathers input for depositing assets.
 * @custom:member smartVault Smart vault for which the deposit is made.
 * @custom:member assets Amounts of assets being deposited.
 * @custom:member receiver Receiver of the deposit NFT.
 * @custom:member referral Referral address.
 * @custom:member doFlush If true, the smart vault will be flushed after the deposit as part of same transaction.
 */
struct DepositBag {
    address smartVault;
    uint256[] assets;
    address receiver;
    address referral;
    bool doFlush;
}

/**
 * @notice Gathers extra input for depositing assets.
 * @custom:member depositor Address making the deposit.
 * @custom:member tokens Tokens of the smart vault.
 * @custom:member strategies Strategies of the smart vault.
 * @custom:member allocations Set allocation of funds between strategies.
 * @custom:member flushIndex Current flush index of the smart vault.
 */
struct DepositExtras {
    address depositor;
    address[] tokens;
    address[] strategies;
    uint16a16 allocations;
    uint256 flushIndex;
}

/**
 * @notice Gathers minted SVTs for a specific fee type.
 * @custom:member depositFees Minted SVTs for deposit fees.
 * @custom:member performanceFees Minted SVTs for performance fees.
 * @custom:member managementFees Minted SVTs for management fees.
 */
struct SmartVaultFeesCollected {
    uint256 depositFees;
    uint256 performanceFees;
    uint256 managementFees;
}

/**
 * @notice Gathers return values of syncing deposits.
 * @custom:member mintedSVTs Amount of SVTs minted.
 * @custom:member dhwTimestamp Timestamp of the last DHW synced.
 * @custom:member feeSVTs Amount of SVTs minted as fees.
 * @custom:member feesCollected Breakdown of amount of SVTs minted as fees.
 * @custom:member initialLockedSVTs Amount of initial locked SVTs.
 * @custom:member sstShares Amount of SSTs claimed for each strategy.
 */
struct DepositSyncResult {
    uint256 mintedSVTs;
    uint256 dhwTimestamp;
    uint256 feeSVTs;
    SmartVaultFeesCollected feesCollected;
    uint256 initialLockedSVTs;
    uint256[] sstShares;
}

/**
 * @custom:member smartVault Smart Vault address
 * @custom:member bag flush index, lastDhwSyncedTimestamp
 * @custom:member strategies strategy addresses
 * @custom:member assetGroup vault asset group token addresses
 * @custom:member dhwIndexes DHW Indexes for given flush index
 * @custom:member dhwIndexesOld DHW Indexes for previous flush index
 * @custom:member fees smart vault fee configuration
 * @return syncResult Result of the smart vault sync.
 */
struct SimulateDepositParams {
    address smartVault;
    // bag[0]: flushIndex,
    // bag[1]: lastDhwSyncedTimestamp,
    uint256[2] bag;
    address[] strategies;
    address[] assetGroup;
    uint16a16 dhwIndexes;
    uint16a16 dhwIndexesOld;
    SmartVaultFees fees;
}

interface IDepositManager {
    /**
     * @notice User redeemed deposit NFTs for SVTs
     * @param smartVault Smart vault address
     * @param claimer Claimer address
     * @param claimedVaultTokens Amount of SVTs claimed
     * @param nftIds NFTs to burn
     * @param nftAmounts NFT shares to burn
     */
    event SmartVaultTokensClaimed(
        address indexed smartVault,
        address indexed claimer,
        uint256 claimedVaultTokens,
        uint256[] nftIds,
        uint256[] nftAmounts
    );

    /**
     * @notice A deposit has been initiated
     * @param smartVault Smart vault address
     * @param receiver Beneficiary of the deposit
     * @param depositId Deposit NFT ID for this deposit
     * @param flushIndex Flush index the deposit was scheduled for
     * @param assets Amount of assets to deposit
     * @param depositor Address that initiated the deposit
     * @param referral Referral address
     */
    event DepositInitiated(
        address indexed smartVault,
        address indexed receiver,
        uint256 indexed depositId,
        uint256 flushIndex,
        uint256[] assets,
        address depositor,
        address referral
    );

    /**
     * @notice Pending deposits were recovered.
     * @param smartVault Smart vault address.
     * @param recoveredAssets Amount of assets recovered.
     */
    event PendingDepositsRecovered(address indexed smartVault, uint256[] recoveredAssets);

    /**
     * @notice Smart vault fees collected.
     * @param smartVault Smart vault address.
     * @param smartVaultFeesCollected Collected smart vault fee amounts.
     */
    event SmartVaultFeesMinted(address indexed smartVault, SmartVaultFeesCollected smartVaultFeesCollected);

    /**
     * @notice Simulate vault synchronization (i.e. DHW was completed, but vault wasn't synced yet)
     */
    function syncDepositsSimulate(SimulateDepositParams calldata parameters)
        external
        view
        returns (DepositSyncResult memory syncResult);

    /**
     * @notice Synchronize vault deposits for completed DHW runs
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param bag flushIndex, lastDhwSyncedTimestamp
     * @param strategies vault strategy addresses
     * @param dhwIndexes dhw indexes for given and previous flushIndex
     * @param assetGroup vault asset group token addresses
     * @param fees smart vault fee configuration
     * @return syncResult Result of the smart vault sync.
     */
    function syncDeposits(
        address smartVault,
        uint256[2] calldata bag,
        // uint256 flushIndex,
        // uint256 lastDhwSyncedTimestamp
        address[] calldata strategies,
        uint16a16[2] calldata dhwIndexes,
        address[] calldata assetGroup,
        SmartVaultFees calldata fees
    ) external returns (DepositSyncResult memory syncResult);

    /**
     * @notice Adds deposits for the next flush cycle.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param bag Deposit parameters.
     * @param bag2 Extra parameters.
     * @return nftId ID of the deposit NFT.
     */
    function depositAssets(DepositBag calldata bag, DepositExtras calldata bag2) external returns (uint256 nftId);

    /**
     * @notice Mark deposits ready to be processed in the next DHW cycle
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param flushIndex index to flush
     * @param strategies vault strategy addresses
     * @param allocations vault strategy allocations
     * @param tokens vault asset group token addresses
     * @return dhwIndexes DHW indexes in which the deposits will be included
     */
    function flushSmartVault(
        address smartVault,
        uint256 flushIndex,
        address[] calldata strategies,
        uint16a16 allocations,
        address[] calldata tokens
    ) external returns (uint16a16 dhwIndexes);

    /**
     * @notice Get the number of SVTs that are available, but haven't been claimed yet, for the given NFT
     * @param smartVaultAddress Smart Vault address
     * @param data NFT deposit NFT metadata
     * @param nftShares amount of NFT shares to burn for SVTs
     * @param mintedSVTs amount of SVTs minted for this flush
     * @param tokens vault asset group addresses
     */
    function getClaimedVaultTokensPreview(
        address smartVaultAddress,
        DepositMetadata memory data,
        uint256 nftShares,
        uint256 mintedSVTs,
        address[] calldata tokens
    ) external view returns (uint256);

    /**
     * @notice Fetch assets deposited in a given vault flush
     */
    function smartVaultDeposits(address smartVault, uint256 flushIdx, uint256 assetGroupLength)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Claim SVTs by burning deposit NFTs.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart Vault address
     * @param nftIds NFT ids to burn
     * @param nftAmounts NFT amounts to burn (support for partial burn)
     * @param tokens vault asset group token addresses
     * @param owner address owning NFTs
     * @param executor address executing the claim transaction
     * @param flushIndexToSync next flush index to sync for the smart vault
     * @return claimedTokens Amount of smart vault tokens claimed.
     */
    function claimSmartVaultTokens(
        address smartVault,
        uint256[] calldata nftIds,
        uint256[] calldata nftAmounts,
        address[] calldata tokens,
        address owner,
        address executor,
        uint256 flushIndexToSync
    ) external returns (uint256 claimedTokens);

    /**
     * @notice Recovers pending deposits from smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault from which to recover pending deposits.
     * @param flushIndex Flush index for which to recover pending deposits.
     * @param strategies Addresses of smart vault's strategies.
     * @param tokens Asset group token addresses.
     * @param emergencyWallet Address of emergency withdraw wallet.
     */
    function recoverPendingDeposits(
        address smartVault,
        uint256 flushIndex,
        address[] calldata strategies,
        address[] calldata tokens,
        address emergencyWallet
    ) external;

    /**
     * @notice Gets current required deposit ratio of a smart vault.
     * @param tokens Asset tokens of the smart vault.
     * @param allocations Allocation between strategies of the smart vault.
     * @param strategies Strategies of the smart vault.
     * @return ratio Required deposit ratio of the smart vault.
     */
    function getDepositRatio(address[] memory tokens, uint16a16 allocations, address[] memory strategies)
        external
        view
        returns (uint256[] memory ratio);
}
