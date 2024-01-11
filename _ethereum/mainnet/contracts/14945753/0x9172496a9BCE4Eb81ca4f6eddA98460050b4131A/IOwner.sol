// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

/**
 * @title IOwner
 * @notice Has all the external functions, events and errors for Owner.sol.
 */
interface IOwner {
    event OwnerChanged(address newOwner);

    ///@dev changeOwner() custom error.
    error Owner__changeOwner__invalidOwnerAddress();

    ///@dev changeRecoveryOwner() custom error.
    error Owner__changeRecoveryOwner__invalidRecoveryOwnerAddress();

    ///@dev initOwner() custom errors.
    error Owner__initOwner__walletInitialized();
    error Owner__initOwner__invalidOwnerAddress();
    error Owner__initOwner__invalidRecoveryOwnerAddress();
    event NewRecoveryOwner(address recoveryOwner);

    /**
     * @dev Changes the owner of the wallet.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(address newOwner) external;

    /**
     * @dev Changes the recoveryOwner address. Only the owner can call this function.
     * @param newRecoveryOwner The new recovery owner address.
     */
    function changeRecoveryOwner(address newRecoveryOwner) external;
}
