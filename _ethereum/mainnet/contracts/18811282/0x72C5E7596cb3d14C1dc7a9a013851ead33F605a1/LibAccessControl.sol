// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./GenericErrors.sol";

/// @title Lib Access Control
/// @author FormalCrypto
/// @notice Provides functionality to manage access to admin functions
library LibAccessControl {
    bytes32 internal constant ACCESS_CONTROL_STORAGE = keccak256("access.control.storage");

    struct AccessStorage {
        mapping(address => mapping(bytes4 => bool)) functionAccess;
    }

    event AccessGranted(address indexed account, bytes4 indexed selector);
    event AccessRevoked(address indexed account, bytes4 indexed selector);

    /**
     * @dev Fetch local storage
     */
    function _getStorage() internal pure returns (AccessStorage storage accStor) {
        bytes32 position = ACCESS_CONTROL_STORAGE;
        assembly {
            accStor.slot := position
        }
    }

    /**
     * @dev Gives the account access to function 
     * @param _account Address of the account to be given access
     * @param _selector Selector of the function to be accessed
     */
    function addAccess(address _account, bytes4 _selector) internal {
        if (_account == address(this)) revert CannotAuthoriseSelf();
        AccessStorage storage accStor = _getStorage();  
        accStor.functionAccess[_account][_selector] = true;
        emit AccessGranted(_account, _selector);
    }

    /**
     * @dev Revokes the account access to finction
     * @param _account Address of the accoun to be revoked access
     * @param _selector Selector of the function to be revoked access
     */
    function revokeAccess(address _account, bytes4 _selector) internal {
        AccessStorage storage accStor = _getStorage();
        accStor.functionAccess[_account][_selector] = false;
        emit AccessRevoked(_account, _selector);
    }

    /**
     * @dev Сhecks if user can call function 
     */
    function isAllowedTo() internal view {
        AccessStorage storage accStor = _getStorage();
        if (!accStor.functionAccess[msg.sender][msg.sig]) revert NotAllowedTo(msg.sender, msg.sig);
    }
}