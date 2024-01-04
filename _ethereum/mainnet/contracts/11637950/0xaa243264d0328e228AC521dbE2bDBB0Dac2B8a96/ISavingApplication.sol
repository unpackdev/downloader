// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @notice Interface of Saving Application.
 * 
 */
interface ISavingApplication {

    function controller() external returns (address);

    function governance() external returns (address);

    function setStrategist(address _strategist) external;

    /**
     * @dev Deposits into vault on behalf of the accounts provided. This can be only called by strategist.
     * @param _accounts Accounts to deposit token from.
     * @param _vaultId ID of the target vault.
     */
    function depositForAccounts(address[] calldata _accounts, uint256 _vaultId) external;
}