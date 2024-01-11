// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import "./IOwner.sol";
import "./SelfAuthorized.sol";

/**
 * @title Owner
 * @notice Handles the owners addresses.
 */
contract Owner is IOwner, SelfAuthorized {
    ///@dev owner should always bet at storage slot 2.
    address public owner;

    ///@dev recovery owner should always be at storage slot 3.
    address public recoveryOwner;

    /**
     * @dev Changes the owner of the wallet.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(address newOwner) external authorized {
        if (newOwner.code.length != 0 || newOwner == address(0))
            revert Owner__changeOwner__invalidOwnerAddress();
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    /**
     * @dev Changes the recoveryOwner address. Only the owner can call this function.
     * @param newRecoveryOwner The new recovery owner address.
     */
    function changeRecoveryOwner(address newRecoveryOwner) external authorized {
        recoveryOwner = newRecoveryOwner;
        if (newRecoveryOwner.code.length != 0 || newRecoveryOwner == address(0))
            revert Owner__changeRecoveryOwner__invalidRecoveryOwnerAddress();
        emit NewRecoveryOwner(recoveryOwner);
    }

    /**
     * @dev Inits the owner. This can only be called at creation.
     * @param _owner The owner of the wallet.
     * @param _recoveryOwner Recovery owner in case the owner looses the main device. Implementation of Sovereign Social Recovery.
     */
    function initOwners(address _owner, address _recoveryOwner) internal {
        // If owner is not address0, the wallet was already initialized...
        if (owner != address(0)) revert Owner__initOwner__walletInitialized();
        checkParams(_owner, _recoveryOwner);
        owner = _owner;
        recoveryOwner = _recoveryOwner;
    }

    /**
     * @dev Checks that the parameters are in bounds.
     * @param _owner The owner of the wallet.
     * @param _recoveryOwner Recovery owner in case the owner looses the main device. Implementation of Sovereign Social Recovery.
     */
    function checkParams(address _owner, address _recoveryOwner) internal view {
        if (_owner.code.length != 0 || _owner == address(0))
            revert Owner__initOwner__invalidOwnerAddress();

        if (_recoveryOwner.code.length != 0 || _recoveryOwner == address(0))
            revert Owner__initOwner__invalidRecoveryOwnerAddress();
    }
}
