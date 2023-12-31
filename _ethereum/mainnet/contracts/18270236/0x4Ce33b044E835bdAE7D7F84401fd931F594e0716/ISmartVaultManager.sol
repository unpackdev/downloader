// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IDepositManager.sol";
import "./ISmartVault.sol";
import "./ISwapper.sol";
import "./IWithdrawalManager.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when user has insufficient balance for redeemal of shares.
 */
error InsufficientBalance(uint256 available, uint256 required);

/**
 * @notice Used when there is nothing to flush.
 */
error NothingToFlush();

/**
 * @notice Used when trying to register a smart vault that was already registered.
 */
error SmartVaultAlreadyRegistered();

/**
 * @notice Used when trying to perform an action for smart vault that was not registered yet.
 */
error SmartVaultNotRegisteredYet();

/**
 * @notice Used when user tries to configure a vault with too large management fee.
 */
error ManagementFeeTooLarge(uint256 mgmtFeePct);

/**
 * @notice Used when user tries to configure a vault with too large performance fee.
 */
error PerformanceFeeTooLarge(uint256 performanceFeePct);

/**
 * @notice Used when smart vault in reallocation has statically set allocation.
 */
error StaticAllocationSmartVault();

/**
 * @notice Used when user tries to configure a vault with too large deposit fee.
 */
error DepositFeeTooLarge(uint256 depositFeePct);

/**
 * @notice Used when user tries redeem on behalf of another user, but the vault does not support it
 */
error RedeemForNotAllowed();

/**
 * @notice Used when trying to flush a vault that still needs to be synced.
 */
error VaultNotSynced();

/**
 * @notice Used when trying to deposit into, redeem from, or flush a smart vault that has only ghost strategies.
 */
error GhostVault();

/**
 * @notice Used when reallocation is called with expired parameters.
 */
error ReallocationParametersExpired();

/* ========== STRUCTS ========== */

/**
 * @notice Struct holding all data for registration of smart vault.
 * @custom:member assetGroupId Underlying asset group of the smart vault.
 * @custom:member strategies Strategies used by the smart vault.
 * @custom:member strategyAllocation Optional. If empty array, values will be calculated on the spot.
 * @custom:member managementFeePct Management fee of the smart vault.
 * @custom:member depositFeePct Deposit fee of the smart vault.
 * @custom:member performanceFeePct Performance fee of the smart vault.
 */
struct SmartVaultRegistrationForm {
    uint256 assetGroupId;
    address[] strategies;
    uint16a16 strategyAllocation;
    uint16 managementFeePct;
    uint16 depositFeePct;
    uint16 performanceFeePct;
}

/**
 * @notice Parameters for reallocation.
 * @custom:member smartVaults Smart vaults to reallocate.
 * @custom:member strategies Set of strategies involved in the reallocation. Should not include ghost strategy, even if some smart vault uses it.
 * @custom:member swapInfo Information for swapping assets before depositing into the protocol.
 * @custom:member depositSlippages Slippages used to constrain depositing into the protocol.
 * @custom:member withdrawalSlippages Slippages used to contrain withdrawal from the protocol.
 * @custom:member exchangeRateSlippages Slippages used to constratrain exchange rates for asset tokens.
 * @custom:member validUntil Sets the maximum timestamp the user is willing to wait to start executing reallocation.
 */
struct ReallocateParamBag {
    address[] smartVaults;
    address[] strategies;
    SwapInfo[][] swapInfo;
    uint256[][] depositSlippages;
    uint256[][] withdrawalSlippages;
    uint256[2][] exchangeRateSlippages;
    uint256 validUntil;
}

struct FlushIndex {
    uint128 current;
    uint128 toSync;
}

/* ========== INTERFACES ========== */

interface ISmartVaultRegistry {
    /**
     * @notice Registers smart vault into the Spool protocol.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * @param smartVault Smart vault to register.
     * @param registrationForm Form with information for registration.
     */
    function registerSmartVault(address smartVault, SmartVaultRegistrationForm calldata registrationForm) external;
}

interface ISmartVaultManager is ISmartVaultRegistry {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Gets do-hard-work indexes.
     * @param smartVault Smart vault.
     * @param flushIndex Flush index.
     * @return dhwIndexes Do-hard-work indexes for flush index of the smart vault.
     */
    function dhwIndexes(address smartVault, uint256 flushIndex) external view returns (uint16a16 dhwIndexes);

    /**
     * @notice Gets latest flush index for a smart vault.
     * @param smartVault Smart vault.
     * @return flushIndex Latest flush index for the smart vault.
     */
    function getLatestFlushIndex(address smartVault) external view returns (uint256 flushIndex);

    /**
     * @notice Gets strategy allocation for a smart vault.
     * @param smartVault Smart vault.
     * @return allocation Strategy allocation for the smart vault.
     */
    function allocations(address smartVault) external view returns (uint16a16 allocation);

    /**
     * @notice Gets strategies used by a smart vault.
     * @param smartVault Smart vault.
     * @return strategies Strategies for the smart vault.
     */
    function strategies(address smartVault) external view returns (address[] memory strategies);

    /**
     * @notice Gets asest group used by a smart vault.
     * @param smartVault Smart vault.
     * @return assetGroupId ID of the asset group used by the smart vault.
     */
    function assetGroupId(address smartVault) external view returns (uint256 assetGroupId);

    /**
     * @notice Gets required deposit ratio for a smart vault.
     * @param smartVault Smart vault.
     * @return ratio Required deposit ratio for the smart vault.
     */
    function depositRatio(address smartVault) external view returns (uint256[] memory ratio);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Flushes deposits and withdrawal for the next do-hard-work.
     * @param smartVault Smart vault to flush.
     */
    function flushSmartVault(address smartVault) external;

    /**
     * @notice Reallocates smart vaults.
     * @dev Requirements:
     * - caller must have a ROLE_REALLOCATOR role
     * - smart vaults must be registered
     * - smart vaults must use same asset group
     * - strategies must represent a set of strategies used by smart vaults
     * @param reallocateParams Paramaters for reallocation.
     */
    function reallocate(ReallocateParamBag calldata reallocateParams) external;

    /**
     * @notice Removes strategy from vaults, and optionally removes it from the system as well.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * - the strategy has to be active (requires ROLE_STRATEGY)
     * @param strategy Strategy address to remove.
     * @param vaults Array of vaults from which to remove the strategy
     * @param disableStrategy Also disable the strategy across the system
     */
    function removeStrategyFromVaults(address strategy, address[] calldata vaults, bool disableStrategy) external;

    /**
     * @notice Syncs smart vault with strategies.
     * @param smartVault Smart vault to sync.
     * @param revertIfError If true, sync will revert if every flush index cannot be synced; if false it will sync all flush indexes it can.
     */
    function syncSmartVault(address smartVault, bool revertIfError) external;

    /**
     * @dev Calculate number of SVTs that haven't been synced yet after DHW runs
     * DHW has minted strategy shares, but vaults haven't claimed them yet.
     * Includes management fees (percentage of assets under management, distributed throughout a year) and deposit fees .
     * Invariants:
     * - There can't be more than once un-synced flush index per vault at any given time.
     * - Flush index can't be synced, if all DHWs haven't been completed yet.
     *
     * Can be used to retrieve the number of SSTs the vault would claim during sync.
     * @param smartVault SmartVault address
     * @return oldTotalSVTs Amount of SVTs before sync
     * @return mintedSVTs Amount of SVTs minted during sync
     * @return feeSVTs Amount of SVTs pertaining to fees
     * @return sstShares Amount of SSTs claimed per strategy
     */
    function simulateSync(address smartVault)
        external
        view
        returns (uint256 oldTotalSVTs, uint256 mintedSVTs, uint256 feeSVTs, uint256[] calldata sstShares);

    /**
     * @dev Simulate sync when burning dNFTs and return their svts value.
     *
     * @param smartVault SmartVault address
     * @param userAddress User address that owns dNFTs
     * @param nftIds Ids of dNFTs
     * @return svts Amount of svts user would get if he burns dNFTs
     */
    function simulateSyncWithBurn(address smartVault, address userAddress, uint256[] calldata nftIds)
        external
        view
        returns (uint256 svts);

    /**
     * @notice Instantly redeems smart vault shares for assets.
     * @param bag Parameters for fast redeemal.
     * @param withdrawalSlippages Slippages guarding redeemal.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFast(RedeemBag calldata bag, uint256[][] calldata withdrawalSlippages)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Simulates redeem fast of smart vault shares.
     * @dev Should only be run by address zero to simulate the redeemal and parse logs.
     * @param bag Parameters for fast redeemal.
     * @param withdrawalSlippages Slippages guarding redeemal.
     * @param redeemer Address of a user to simulate redeem for.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFastView(RedeemBag calldata bag, uint256[][] calldata withdrawalSlippages, address redeemer)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Claims withdrawal of assets by burning withdrawal NFT.
     * @dev Requirements:
     * - withdrawal NFT must be valid
     * @param smartVault Address of the smart vault that issued the withdrawal NFT.
     * @param nftIds ID of withdrawal NFT to burn.
     * @param nftAmounts amounts
     * @param receiver Receiver of claimed assets.
     * @return assetAmounts Amounts of assets claimed.
     * @return assetGroupId ID of the asset group.
     */
    function claimWithdrawal(
        address smartVault,
        uint256[] calldata nftIds,
        uint256[] calldata nftAmounts,
        address receiver
    ) external returns (uint256[] memory assetAmounts, uint256 assetGroupId);

    /**
     * @notice Claims smart vault tokens by burning the deposit NFT.
     * @dev Requirements:
     * - deposit NFT must be valid
     * - flush must be synced
     * @param smartVaultAddress Address of the smart vault that issued the deposit NFT.
     * @param nftIds ID of the deposit NFT to burn.
     * @param nftAmounts amounts
     * @return claimedAmount Amount of smart vault tokens claimed.
     */
    function claimSmartVaultTokens(address smartVaultAddress, uint256[] calldata nftIds, uint256[] calldata nftAmounts)
        external
        returns (uint256 claimedAmount);

    /**
     * @notice Initiates a withdrawal process and mints a withdrawal NFT. Once all DHWs are executed, user can
     * use the withdrawal NFT to claim the assets.
     * Optionally, caller can pass a list of deposit NFTs to unwrap.
     * @param bag smart vault address, amount of shares to redeem, nft ids and amounts to burn
     * @param receiver address that will receive the withdrawal NFT
     * @param doFlush optionally flush the smart vault
     * @return receipt ID of the receipt withdrawal NFT.
     */
    function redeem(RedeemBag calldata bag, address receiver, bool doFlush) external returns (uint256 receipt);

    /**
     * @notice Initiates a withdrawal process and mints a withdrawal NFT. Once all DHWs are executed, user can
     * use the withdrawal NFT to claim the assets.
     * Optionally, caller can pass a list of deposit NFTs to unwrap.
     * @param bag smart vault address, amount of shares to redeem, nft ids and amounts to burn
     * @param owner address that owns the shares to be redeemed and will receive the withdrawal NFT
     * @param doFlush optionally flush the smart vault
     * @return receipt ID of the receipt withdrawal NFT.
     */
    function redeemFor(RedeemBag calldata bag, address owner, bool doFlush) external returns (uint256 receipt);

    /**
     * @notice Initiated a deposit and mints a deposit NFT. Once all DHWs are executed, user can
     * unwrap the deposit NDF and claim his SVTs.
     * @param bag smartVault address, assets, NFT receiver address, referral address, doFlush
     * @return receipt ID of the receipt deposit NFT.
     */
    function deposit(DepositBag calldata bag) external returns (uint256 receipt);

    /**
     * @notice Recovers pending deposits from smart vault to emergency wallet.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * - all strategies of the smart vault need to be ghost strategies
     * @param smartVault Smart vault from which to recover pending deposits.
     */
    function recoverPendingDeposits(address smartVault) external;

    /* ========== EVENTS ========== */

    /**
     * @notice Smart vault has been flushed
     * @param smartVault Smart vault address
     * @param flushIndex Flush index
     */
    event SmartVaultFlushed(address indexed smartVault, uint256 flushIndex);

    /**
     * @notice Smart vault has been synced
     * @param smartVault Smart vault address
     * @param flushIndex Flush index
     */
    event SmartVaultSynced(address indexed smartVault, uint256 flushIndex);

    /**
     * @notice Smart vault has been registered
     * @param smartVault Smart vault address
     * @param registrationForm Smart vault configuration
     */
    event SmartVaultRegistered(address indexed smartVault, SmartVaultRegistrationForm registrationForm);

    /**
     * @notice Strategy was removed from the vault
     * @param strategy Strategy address
     * @param vault Vault to remove the strategy from
     */
    event StrategyRemovedFromVault(address indexed strategy, address indexed vault);

    /**
     * @notice Vault was reallocation executed
     * @param smartVault Smart vault address
     * @param newAllocations new vault strategy allocations
     */
    event SmartVaultReallocated(address indexed smartVault, uint16a16 newAllocations);
}
