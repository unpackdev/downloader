// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./MulticallUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./Roles.sol";

contract AccessManager is Initializable, AccessControlUpgradeable,  MulticallUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address admin) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function setNewRole(bytes32 role, bytes32 admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, admin);
    }

    uint256[49] private __gap;
}
