// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
// (https://github.com/unreal-accelerator/contracts)
pragma solidity ^0.8.9;

/**
 * @title AccessControlAdmin
 * @dev This contract provides a common way to control access for minting contracts
 * The deployer wallet is set saved as the initial admin upon deployment.
 * Admin role is inherited from AccessControlEnumerable
 */

import "./AccessControlEnumerable.sol";

contract AccessControlAdmin is AccessControlEnumerable {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
    @dev Grant an account Admin role. Role check is internal. 
     */
    function grantAdminRole(address account) external {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    @dev Remove an account Admin role. Role check is internal. 
     */
    function removeAdminRole(address account) external {
        require(account != _msgSender(), "Cannot remove self");
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    @dev Grant an account a role. This contract only supports the Admin role 
     */
    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        require(account != address(0), "Cannot grant role to null");
        require(role == DEFAULT_ADMIN_ROLE, "Invalid role");
        super._grantRole(role, account);
    }

    /**
    @dev Modifier to check for Admin role
     */
    modifier onlyAuthorized() {
        validateAuthorized();
        _;
    }

    function validateAuthorized() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");
    }

    /**
    @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return AccessControlEnumerable.supportsInterface(interfaceId);
    }
}
