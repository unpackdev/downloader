// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

/**
 * @title IAccountAbstraction
 * @notice Has all the external functions, events and errors for AccountAbstraction.sol.
 */
interface IAccountAbstraction {
    event EntryPointChanged(address newEntrypoint);

    ///@dev innitEntryPoint() custom error.
    error AA__initEntryPoint__invalidEntryPoint();
    error AA__initEntryPoint__invalidSignature();

    ///@dev withdrawDeposit() custom error.
    error AA__withdrawDeposit__insufficientBalance();

    ///@dev changeEntryPoint() custom error.
    error AA__changeEntryPoint__invalidEntryPoint();

    /**
     * @dev Withdraws the stake deposit from EntryPoint.
     * @param amount Amount to withdraw.
     */
    function withdrawDeposit(uint256 amount) external;

    /**
     * @dev Changes the entry point address.
     * @param newEntryPoint  New entry point address.
     */
    function changeEntryPoint(address newEntryPoint) external;
}
