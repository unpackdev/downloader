// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import "./CohortFactory.sol";
import "./IERC20.sol";
import "./IUnifarmCohortRegistryUpgradeable.sol";
import "./IWETH.sol";

/// @title CohortHelper library
/// @author UNIFARM
/// @notice we have various util functions.which is used in protocol directly
/// @dev all the functions are internally used in the protocol.

library CohortHelper {
    /**
     * @dev getBlockNumber obtain current block from the chain.
     * @return current block number
     */

    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @dev get current owner of the factory contract.
     * @param factory factory contract address.
     * @return factory owner address
     */

    function owner(address factory) internal view returns (address) {
        return CohortFactory(factory).owner();
    }

    /**
     * @dev validating the sender
     * @param factory factory contract address
     * @return registry registry contract address
     * @return nftManager nft Manager contract address
     * @return rewardRegistry reward registry contract address
     */

    function verifyCaller(address factory)
        internal
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        )
    {
        (registry, nftManager, rewardRegistry) = getStorageContracts(factory);
        require(msg.sender == nftManager, 'ONM');
    }

    /**
     * @dev get cohort details
     * @param registry registry contract address
     * @param cohortId cohort contract address
     * @return cohortVersion specfic cohort version.
     * @return startBlock start block of a cohort.
     * @return endBlock end block of a cohort.
     * @return epochBlocks epoch blocks in particular cohort.
     * @return hasLiquidityMining indicator for liquidity mining.
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards.
     * @return hasCohortLockinAvaliable denotes cohort lockin.
     */

    function getCohort(address registry, address cohortId)
        internal
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        )
    {
        (
            cohortVersion,
            startBlock,
            endBlock,
            epochBlocks,
            hasLiquidityMining,
            hasContainsWrappedToken,
            hasCohortLockinAvaliable
        ) = IUnifarmCohortRegistryUpgradeable(registry).getCohort(cohortId);
    }

    /**
     * @dev obtain particular cohort farm token details
     * @param registry registry contract address
     * @param cohortId cohort contract address
     * @param farmId farm Id
     * @return fid farm Id
     * @return farmToken farm token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specfic farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(
        address registry,
        address cohortId,
        uint32 farmId
    )
        internal
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        )
    {
        (fid, farmToken, userMinStake, userMaxStake, totalStakeLimit, decimals, skip) = IUnifarmCohortRegistryUpgradeable(registry).getCohortToken(
            cohortId,
            farmId
        );
    }

    /**
     * @dev derive booster pack details available for a specfic cohort.
     * @param registry registry contract address
     * @param cohortId cohort contract Address
     * @param bpid booster pack id.
     * @return cohortId_ cohort address.
     * @return paymentToken_ payment token address.
     * @return boosterVault the booster vault address.
     * @return boosterPackAmount the booster pack amount.
     */

    function getBoosterPackDetails(
        address registry,
        address cohortId,
        uint256 bpid
    )
        internal
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        )
    {
        (cohortId_, paymentToken_, boosterVault, boosterPackAmount) = IUnifarmCohortRegistryUpgradeable(registry).getBoosterPackDetails(
            cohortId,
            bpid
        );
    }

    /**
     * @dev calculate exact balance of a particular cohort.
     * @param token token address
     * @param totalStaking total staking of a token
     * @return cohortBalance current cohort balance
     */

    function getCohortBalance(address token, uint256 totalStaking) internal view returns (uint256 cohortBalance) {
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        cohortBalance = contractBalance - totalStaking;
    }

    /**
     * @dev get all storage contracts from factory contract.
     * @param factory factory contract address
     * @return registry registry contract address
     * @return nftManager nftManger contract address
     * @return rewardRegistry reward registry address
     */

    function getStorageContracts(address factory)
        internal
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        )
    {
        (registry, nftManager, rewardRegistry) = CohortFactory(factory).getStorageContracts();
    }

    /**
     * @dev handle deposit WETH
     * @param weth WETH address
     * @param amount deposit amount
     */

    function depositWETH(address weth, uint256 amount) internal {
        IWETH(weth).deposit{value: amount}();
    }

    /**
     * @dev validate stake lock status
     * @param registry registry address
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(
        address registry,
        address cohortId,
        uint32 farmId
    ) internal view {
        IUnifarmCohortRegistryUpgradeable(registry).validateStakeLock(cohortId, farmId);
    }

    /**
     * @dev validate unstake lock status
     * @param registry registry address
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(
        address registry,
        address cohortId,
        uint32 farmId
    ) internal view {
        IUnifarmCohortRegistryUpgradeable(registry).validateUnStakeLock(cohortId, farmId);
    }
}
