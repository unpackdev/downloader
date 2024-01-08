// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./RolesStore.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    
    /* GETTER METHODS */

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function _has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles._has: ZERO_ADDRESS");
        return role.bearer[account];
    }

    /**
     * @dev Check if this role has at least one account assigned to it.
     * @return bool
     */
    function _atLeastOneBearer(uint256 numberOfBearers) internal pure returns (bool) {
        if (numberOfBearers > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Give an account access to this role.
     */
    function _add(
        Role storage role,
        address account
    )
        internal
    {
        require(
            !_has(role, account),
            "Roles._add: ALREADY_ASSIGNED"
        );

        role.bearer[account] = true;
        role.numberOfBearers += 1;
    }

    /**
     * @dev Remove an account's access to this role. (1 account minimum enforced for safeRemove)
     */
    function _safeRemove(
        Role storage role,
        address account
    )
        internal
    {
        require(
            _has(role, account),
            "Roles._safeRemove: INVALID_ACCOUNT"
        );
        uint256 numberOfBearers = role.numberOfBearers -= 1; // roles that use safeRemove must implement initializeRole() and onlyIntialized() and must set the contract deployer as the first account, otherwise this can underflow below zero
        require(
            _atLeastOneBearer(numberOfBearers),
            "Roles._safeRemove: MINIMUM_ACCOUNTS"
        );
        
        role.bearer[account] = false;
    }

    /**
     * @dev Remove an account's access to this role. (no minimum enforced)
     */
    function _remove(Role storage role, address account) internal {
        require(_has(role, account), "Roles.remove: INVALID_ACCOUNT");
        role.numberOfBearers -= 1;
        
        role.bearer[account] = false;
    }
}