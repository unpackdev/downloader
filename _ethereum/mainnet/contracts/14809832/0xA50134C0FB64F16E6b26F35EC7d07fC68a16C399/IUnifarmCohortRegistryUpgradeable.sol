// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title IUnifarmCohortRegistryUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm Cohort Registry.

interface IUnifarmCohortRegistryUpgradeable {
    /**
     * @notice set tokenMetaData for a particular cohort farm
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param fid_ farm id
     * @param farmToken_ farm token address
     * @param userMinStake_ user minimum stake
     * @param userMaxStake_ user maximum stake
     * @param totalStakeLimit_ total stake limit
     * @param decimals_ token decimals
     * @param skip_ it can be skip or not during unstake
     */

    function setTokenMetaData(
        address cohortId,
        uint32 fid_,
        address farmToken_,
        uint256 userMinStake_,
        uint256 userMaxStake_,
        uint256 totalStakeLimit_,
        uint8 decimals_,
        bool skip_
    ) external;

    /**
     * @notice a function to set particular cohort details
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param cohortVersion_ cohort version
     * @param startBlock_ start block of a cohort
     * @param endBlock_ end block of a cohort
     * @param epochBlocks_ epochBlocks of a cohort
     * @param hasLiquidityMining_ true if lp tokens can be stake here
     * @param hasContainsWrappedToken_ true if wTokens exist in rewards
     * @param hasCohortLockinAvaliable_ cohort lockin flag
     */

    function setCohortDetails(
        address cohortId,
        string memory cohortVersion_,
        uint256 startBlock_,
        uint256 endBlock_,
        uint256 epochBlocks_,
        bool hasLiquidityMining_,
        bool hasContainsWrappedToken_,
        bool hasCohortLockinAvaliable_
    ) external;

    /**
     * @notice to add a booster pack in a particular cohort
     * @dev only called by owner access or multicall
     * @param cohortId_ cohort address
     * @param paymentToken_ payment token address
     * @param boosterVault_ booster vault address
     * @param bpid_ booster pack Id
     * @param boosterPackAmount_ booster pack amount
     */

    function addBoosterPackage(
        address cohortId_,
        address paymentToken_,
        address boosterVault_,
        uint256 bpid_,
        uint256 boosterPackAmount_
    ) external;

    /**
     * @notice update multicall contract address
     * @dev only called by owner access
     * @param newMultiCallAddress new multicall address
     */

    function updateMulticall(address newMultiCallAddress) external;

    /**
     * @notice lock particular cohort contract
     * @dev only called by owner access or multicall
     * @param cohortId cohort contract address
     * @param status true for lock vice-versa false for unlock
     */

    function setWholeCohortLock(address cohortId, bool status) external;

    /**
     * @notice lock particular cohort contract action. (`STAKE` | `UNSTAKE`)
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortLockStatus(
        address cohortId,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice lock the particular farm action (`STAKE` | `UNSTAKE`) in a cohort
     * @param cohortSalt mixture of cohortId and tokenId
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortTokenLockStatus(
        bytes32 cohortSalt,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice validate cohort stake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice validate cohort unstake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice get farm token details in a specific cohort
     * @param cohortId particular cohort address
     * @param farmId farmId of particular cohort
     * @return fid farm Id
     * @return farmToken farm Token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specific farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(address cohortId, uint32 farmId)
        external
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        );

    /**
     * @notice get specific cohort details
     * @param cohortId cohort address
     * @return cohortVersion specific cohort version
     * @return startBlock start block of a unifarm cohort
     * @return endBlock end block of a unifarm cohort
     * @return epochBlocks epoch blocks in particular cohort
     * @return hasLiquidityMining indicator for liquidity mining
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @return hasCohortLockinAvaliable denotes cohort lockin
     */

    function getCohort(address cohortId)
        external
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        );

    /**
     * @notice get booster pack details for a specific cohort
     * @param cohortId cohort address
     * @param bpid booster pack Id
     * @return cohortId_ cohort address
     * @return paymentToken_ payment token address
     * @return boosterVault booster vault address
     * @return boosterPackAmount booster pack amount
     */

    function getBoosterPackDetails(address cohortId, uint256 bpid)
        external
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        );

    /**
     * @notice emit on each farm token update
     * @param cohortId cohort address
     * @param farmToken farm token address
     * @param fid farm Id
     * @param userMinStake amount that user can minimum stake
     * @param userMaxStake amount that user can maximum stake
     * @param totalStakeLimit total stake limit for the specific farm
     * @param decimals farm token decimals
     * @param skip it can be skip or not during unstake
     */

    event TokenMetaDataDetails(
        address indexed cohortId,
        address indexed farmToken,
        uint32 indexed fid,
        uint256 userMinStake,
        uint256 userMaxStake,
        uint256 totalStakeLimit,
        uint8 decimals,
        bool skip
    );

    /**
     * @notice emit on each update of cohort details
     * @param cohortId cohort address
     * @param cohortVersion specific cohort version
     * @param startBlock start block of a unifarm cohort
     * @param endBlock end block of a unifarm cohort
     * @param epochBlocks epoch blocks in particular unifarm cohort
     * @param hasLiquidityMining indicator for liquidity mining
     * @param hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @param hasCohortLockinAvaliable denotes cohort lockin
     */

    event AddedCohortDetails(
        address indexed cohortId,
        string indexed cohortVersion,
        uint256 startBlock,
        uint256 endBlock,
        uint256 epochBlocks,
        bool indexed hasLiquidityMining,
        bool hasContainsWrappedToken,
        bool hasCohortLockinAvaliable
    );

    /**
     * @notice emit on update of each booster pacakge
     * @param cohortId the cohort address
     * @param bpid booster pack id
     * @param paymentToken the payment token address
     * @param boosterPackAmount the booster pack amount
     */

    event BoosterDetails(address indexed cohortId, uint256 indexed bpid, address paymentToken, uint256 boosterPackAmount);
}
