// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IUnifarmCohortFactoryUpgradeable {
    /**
     * @notice set storage contracts for unifarm cohorts
     * @dev called by only owner access
     * @param registry_ registry address
     * @param nftManager_ NFT manager address
     * @param rewardRegistry_ reward registry address
     */

    function setStorageContracts(
        address registry_,
        address nftManager_,
        address rewardRegistry_
    ) external;

    /**
    @notice function helps to deploy unifarm cohort contracts
    @dev only owner access can deploy new cohorts
    @param salt random bytes
    @return cohortId the deployed cohort contract address
   */

    function createUnifarmCohort(bytes32 salt) external returns (address cohortId);

    /**
     * @notice the function helps to derive deployed cohort address
     * @dev calculate the deployed cohort contract address by salt
     * @param salt random bytes
     * @return deployed cohort address
     */

    function computeCohortAddress(bytes32 salt) external view returns (address);

    /**
     * @notice derive storage contracts
     * @return registry the registry address
     * @return  nftManager nft manager address
     * @return  rewardRegistry reward registry address
     */

    function getStorageContracts()
        external
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        );

    /**
     * @notice get number of cohorts
     * @return number of cohorts.
     */

    function obtainNumberOfCohorts() external view returns (uint256);
}
