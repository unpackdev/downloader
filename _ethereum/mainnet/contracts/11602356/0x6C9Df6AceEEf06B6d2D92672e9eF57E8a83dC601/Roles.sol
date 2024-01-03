// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

abstract contract Roles is Ownable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    EnumerableSet.AddressSet _admins;

    constructor(address[3] memory accounts) {
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        for (uint256 i = 0; i < accounts.length; ++i) {
            if (accounts[i] != address(0)) {
                _setupRole(DEFAULT_ADMIN_ROLE, accounts[i]);
                _setupRole(ADMIN_ROLE, accounts[i]);
                _admins.add(accounts[i]);
            }
        }
    }

    modifier onlySuperAdmin() {
        require(isSuperAdmin(_msgSender()), "Restricted to super admins.");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Restricted to admins.");
        _;
    }

    modifier onlySuperAdminOrAdmin() {
        require(
            isSuperAdmin(_msgSender()) || isAdmin(_msgSender()),
            "Restricted to super admins or admins."
        );
        _;
    }

    function addSuperAdmin(address account)
        public
        onlySuperAdmin
    {
        grantRole(DEFAULT_ADMIN_ROLE, account);
        _admins.add(account);
    }

    function renounceSuperAdmin()
        public
        onlySuperAdmin
    {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _admins.remove(_msgSender());
    }

    function addAdmin(address account)
        public
        onlySuperAdmin
    {
        grantRole(ADMIN_ROLE, account);
        _admins.add(account);
    }

    function removeAdmin(address account)
        public
        onlySuperAdmin
    {
        revokeRole(ADMIN_ROLE, account);
        _admins.remove(account);
    }

    function renounceAdmin()
        public
        onlyAdmin
    {
        renounceRole(ADMIN_ROLE, _msgSender());
        _admins.remove(_msgSender());
    }

    function isSuperAdmin(address account)
        public
        view
        returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isAdmin(address account)
        public
        view
        returns (bool)
    {
        return hasRole(ADMIN_ROLE, account);
    }
}
