// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @notice Interface of Account contract.
 * 
 * Each account has one owner. Owner can grant and revole admins, and admins
 * can grant and revoke operators. Owner, admins and operators 
 */
interface IAccount {

    /**
     * @dev Returns the owner address of the account.
     */
    function owner() external view returns (address);

    /**
     * @dev Checks whether a user is an operator of the account.
     */
    function isOperator(address _user) external view returns (bool);

    /**
     * @dev Allows the spender address to spend up to the amount of token.
     * @param _tokenAddress Address of the ERC20 that can spend.
     * @param _targetAddress Address which can spend the ERC20.
     * @param _amount Amount of ERC20 that can be spent by the target address.
     */
    function approveToken(address _tokenAddress, address _targetAddress, uint256 _amount) external;

    /**
     * @notice Performs a generic transaction on the Account contract.
     * @param _target The address for the target contract.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invoke(address _target, uint256 _value, bytes calldata _data) external returns (bytes calldata);
}