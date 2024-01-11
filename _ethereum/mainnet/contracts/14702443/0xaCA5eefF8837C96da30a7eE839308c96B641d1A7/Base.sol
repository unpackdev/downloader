// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC165.sol";

import "./console.sol";
/**
 * @dev base contract that includes functionality common to all contracts 
 */
contract Base is
    ERC165,
    AccessControl,
    Ownable,
    ReentrancyGuard {

    constructor ()  {
        // owner is the only address permitted hold DEFAULT_ADMIN_ROLE and manage access for this contract
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        // owner is also CONTRACT_ADMIN_ROLE by default (revocable)
        _grantRole(CONTRACT_ADMIN_ROLE, owner());
    }

    // no account other than owner is permitted to have DEFAULT_ADMIN_ROLE
    error DefaultAdminRoleNotPermitted();
    // revokeRole may not be called on owner's address for DEFAULT_ADMIN_ROLE
    error OwnerAdminRoleIrrevocable();
    // renouncing owner roles is not allowed because we have explicitly disabled it
    error OwnerAdminRoleUnrenounceable();
    
    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC165) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev overrides AccessControl.grantRole function
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        // no account other than owner is permitted to have DEFAULT_ADMIN_ROLE
        if(role == DEFAULT_ADMIN_ROLE) revert DefaultAdminRoleNotPermitted();
        _grantRole(role, account);
    }

    /**
     * @dev overrides AccessControl.renounceRole function
     */
    function renounceRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        // owner must always have DEFAULT_ADMIN_ROLE
        if(role == DEFAULT_ADMIN_ROLE && account == owner()) revert OwnerAdminRoleUnrenounceable();
        _revokeRole(role, account);
    }

    /**
     * @dev overrides AccessControl.revokeRole function
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        // owner must always have DEFAULT_ADMIN_ROLE
        if(role == DEFAULT_ADMIN_ROLE && account == owner()) revert OwnerAdminRoleIrrevocable();
        _revokeRole(role, account);
    }

}
