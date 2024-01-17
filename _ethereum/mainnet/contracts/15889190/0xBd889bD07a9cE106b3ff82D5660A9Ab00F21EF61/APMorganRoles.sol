// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

abstract contract APMorganRoles is Initializable, AccessControlUpgradeable {
    /// Roles
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant APMORGAN_ROLE = keccak256("APMORGAN_ROLE");

    /// @notice initialize ap morgan access control contract
    function __roles_init(address admin, address apMorgan)
        internal
        onlyInitializing
    {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(APMORGAN_ROLE, apMorgan);
    }
}
