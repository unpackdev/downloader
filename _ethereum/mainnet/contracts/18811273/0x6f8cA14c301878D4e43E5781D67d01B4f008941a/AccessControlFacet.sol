// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibAccessControl.sol";
import "./LibDiamond.sol";
import "./GenericErrors.sol";

/// @title Access Manager Facet
/// @author FormalCrypto
/// @notice Provides functionality for managing method level access control
contract AccessControlFacet {

    event AccessGranted(address indexed account, bytes4 indexed selector);
    event AccessRevoked(address indexed account, bytes4 indexed selector);

    /**
     * Gives specific address access to function
     * @param _account Address to be given access
     * @param _selector Selector of the function to be accessed
     */
    function grantAccess(address _account, bytes4 _selector) external {
        if (msg.sender == address(this)) revert CannotAuthoriseSelf();
        LibDiamond.enforceIsContractOwner();

        LibAccessControl.addAccess(_account, _selector);
        emit AccessGranted(_account, _selector);
    }

    /**
     * Revokes access form specific address
     * @param _account Address of the accoun to be revoked access 
     * @param _selector Selector of the function to be revoked access
     */
    function revokeAccess(address _account, bytes4 _selector) external {
        if (msg.sender == address(this)) revert CannotAuthoriseSelf();
        LibDiamond.enforceIsContractOwner();

        LibAccessControl.revokeAccess(_account, _selector);
        emit AccessRevoked(_account, _selector);
    }

    function hasAccess(address _account, bytes4 _selector) external view returns (bool) {
        return LibAccessControl._getStorage().functionAccess[_account][_selector];
    }
}