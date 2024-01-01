// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILightAccountFactory {
    /**
     * @notice Create an account, and return its address.
     * Returns the address even if the account is already deployed.
     * @dev During UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation.
     * @param owner The owner of the account to be created
     * @param salt A salt, which can be changed to create multiple accounts with the same owner
     * @return ret The address of either the newly deployed account or an existing account with this owner and salt
     */
    function createAccount(address owner, uint256 salt) external returns (address ret);

    /**
     * @notice Calculate the counterfactual address of this account as it would be returned by createAccount()
     * @param owner The owner of the account to be created
     * @param salt A salt, which can be changed to create multiple accounts with the same owner
     * @return The address of the account that would be created with createAccount()
     */
    function getAddress(address owner, uint256 salt) external view returns (address);
}
