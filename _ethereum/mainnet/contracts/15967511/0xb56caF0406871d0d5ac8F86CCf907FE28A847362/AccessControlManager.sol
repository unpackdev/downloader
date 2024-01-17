// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./AccessControlEnumerable.sol";

contract AccessControlManager is AccessControlEnumerable {
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant RWA_MANAGER_ROLE = keccak256("RWA_MANAGER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CRON_MANAGER_ROLE = keccak256("CRON_MANAGER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(WHITELIST_ROLE, ADMIN_ROLE);
        _setRoleAdmin(RWA_MANAGER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CRON_MANAGER_ROLE, ADMIN_ROLE);
    }

    function changeRoleAdmin(bytes32 role, bytes32 newAdminRole)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(role != DEFAULT_ADMIN_ROLE, "NA");
        _setRoleAdmin(role, newAdminRole);
    }

    function isOwner(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isWhiteListed(address account) external view returns (bool) {
        return hasRole(WHITELIST_ROLE, account);
    }

    function isRWAManager(address account) external view returns (bool) {
        return hasRole(RWA_MANAGER_ROLE, account);
    }

    function isAdmin(address account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function isCronManager(address account) external view returns (bool) {
        return hasRole(CRON_MANAGER_ROLE, account);
    }

    function owner() external view returns (address) {
        return
            getRoleMember(
                DEFAULT_ADMIN_ROLE,
                getRoleMemberCount(DEFAULT_ADMIN_ROLE) - 1
            );
    }
}
