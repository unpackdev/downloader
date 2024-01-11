// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./VaultAPI.sol";

/**
 * @notice
 *  Based on BaseRouter Yearn Finance Smart Contract
 *
 */
interface IBaseRouterUpgradeable {
    /**
     * @notice
     *  Used to update the yearn registry.
     * @param _registry The new _registry address.
     */
    function setRegistry(address _registry) external;

    /**
     * @notice
     *  Used to get the most revent vault for the token using the registry.
     * @return An instance of a VaultAPI
     */
    function bestVault(address token) external view returns (VaultAPI);

    /**
     * @notice
     *  Used to get all vaults from the registery for the token
     * @return An array containing instances of VaultAPI
     */
    function allVaults(address token) external view returns (VaultAPI[] memory);

    function updateVaultCache(address token)
        external
        returns (VaultAPI[] memory vaults);

    /**
     * @notice
     *  Used to get the balance of an account accross all the vaults for a token.
     *  @dev will be used to get the router balance using totalVaultBalance(address(this)).
     *  @param account The address of the account.
     *  @return balance of token for the account accross all the vaults.
     */
    function totalVaultBalance(address token, address account)
        external
        view
        returns (uint256 balance);

    /**
     * @notice
     *  Used to get the TVL on the underlying vaults.
     *  @return assets the sum of all the assets managed by the underlying vaults.
     */
    function totalAssets(address token) external view returns (uint256 assets);

    function verifyVaultExist(address token) external view;
}
