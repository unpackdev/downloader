// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IAccessControlUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./AccessControlDefaultAdminRulesUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ContextUpgradeable.sol";

abstract contract BaseContract is
    Initializable,
    UUPSUpgradeable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    AccessControlDefaultAdminRulesUpgradeable,
    PausableUpgradeable
{
    /// @notice Only accounts with this role are allowed to upgrade the contract
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    
    uint48 public constant DEFAULT_INITIAL_DELAY = 1 hours;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __BaseContract_init(
        address initialDefaultAdmin
    ) internal onlyInitializing {
        __UUPSUpgradeable_init();
        __AccessControlEnumerable_init();
        __Pausable_init();
        __BaseContract_init_unchained(initialDefaultAdmin);
    }

    function __BaseContract_init_unchained(
        address initialDefaultAdmin
    ) internal onlyInitializing {
        __AccessControlDefaultAdminRules_init(
            DEFAULT_INITIAL_DELAY,
            initialDefaultAdmin
        );

        _grantRole(UPGRADER_ROLE, initialDefaultAdmin);
        _setRoleAdmin(UPGRADER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function grantRole(
        bytes32 role,
        address account
    )
        public
        virtual
        override(
            AccessControlDefaultAdminRulesUpgradeable,
            AccessControlUpgradeable,
            IAccessControlUpgradeable
        )
    {
        super.grantRole(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    )
        public
        virtual
        override(
            AccessControlDefaultAdminRulesUpgradeable,
            AccessControlUpgradeable,
            IAccessControlUpgradeable
        )
    {
        super.revokeRole(role, account);
    }

    function renounceRole(
        bytes32 role,
        address account
    )
        public
        virtual
        override(
            AccessControlDefaultAdminRulesUpgradeable,
            AccessControlUpgradeable,
            IAccessControlUpgradeable
        )
    {
        super.renounceRole(role, account);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            AccessControlDefaultAdminRulesUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    )
        internal
        virtual
        override(
            AccessControlDefaultAdminRulesUpgradeable,
            AccessControlUpgradeable
        )
    {
        super._setRoleAdmin(role, adminRole);
    }

    function _grantRole(
        bytes32 role,
        address account
    )
        internal
        virtual
        override(
            AccessControlDefaultAdminRulesUpgradeable,
            AccessControlEnumerableUpgradeable
        )
    {
        super._grantRole(role, account);
    }

    function _revokeRole(
        bytes32 role,
        address account
    )
        internal
        virtual
        override(
            AccessControlDefaultAdminRulesUpgradeable,
            AccessControlEnumerableUpgradeable
        )
    {
        super._revokeRole(role, account);
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(UPGRADER_ROLE) {}
}
