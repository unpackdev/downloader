// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./RolesLib.sol";
/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRoleUpgradeable is ContextUpgradeable, OwnableUpgradeable {
    using RolesLib for RolesLib.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    RolesLib.Role private _whitelistAdmins;

    function __WhitelistAdminRole_init_unchained() internal {
	// no-op
    }
    function __WhitelistAdminRole_init() internal initializer {
        __WhitelistAdminRole_init_unchained();
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return account == owner();
    }

    function addWhitelistAdmin(address /* account */) public view onlyWhitelistAdmin {
        revert("unsupported");
    }

    function renounceWhitelistAdmin() public pure {
        revert("unsupported");
    }
}
