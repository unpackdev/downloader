// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Initializable.sol";

import "./UUPSUpgradeable.sol";

import "./EIP712Upgradeable.sol";

import "./AccessControlEnumerableUpgradeable.sol";

import "./IAccessManagerUpgradeable.sol";

import "./Constants.sol";

contract AccessManagerUpgradeable is IAccessManagerUpgradeable, Initializable, UUPSUpgradeable, EIP712Upgradeable, AccessControlEnumerableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_, address[] calldata operators_, string calldata name_, string calldata version_) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __EIP712_init(name_, version_);
        _grantRoles(MINTER_ROLE, operators_);
        _grantRoles(OPERATOR_ROLE, operators_);
        _grantRole(UPGRADER_ROLE, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    function admin() public view override returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function changeAdmin(address newAdmin_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin_);
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
