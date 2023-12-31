// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title IOwnerTwoStep
 * @notice Interface for the OwnerTwoStep contract
 */
interface IOwnerTwoStep {

    // ***************************************************************
    // * =================== USER INTERFACE ======================== *
    // ***************************************************************

    /**
     * @notice Starts the ownership transfer of the contract to a new account. Replaces the 
     *   pending transfer if there is one. 
     * @dev Can only be called by the current owner.
     * @param newOwner_ The address of the new owner
     */
    function transferOwnership(address newOwner_) external;

    /**
     * @notice Completes the transfer process to a new owner.
     * @dev only callable by the pending owner that is accepting the new ownership.
     */
    function acceptOwnership() external;

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     */
    function renounceOwnership() external;

    // ***************************************************************
    // * =================== VIEW FUNCTIONS ======================== *
    // ***************************************************************

    /**
     * @notice Getter function to find out the current owner address
     * @return owner The current owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Getter function to find out the pending owner address
     * @dev The pending address is 0 when there is no transfer of owner in progress
     * @return pendingOwner The pending owner address, if any
     */
    function pendingOwner() external view returns (address);
}
