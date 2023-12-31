// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./AccessControlEnumerableUpgradeable.sol";
import "./SignatureVerifierUpgradeable.sol";

import "./IRoleManagerUpgradeable.sol";

import "./Constants.sol";

contract RoleManagerUpgradeable is
    Initializable,
    UUPSUpgradeable,
    IRoleManagerUpgradeable,
    AccessControlEnumerableUpgradeable,
    SignatureVerifierUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata version_,
        address signer_,
        uint8 threshold_
    ) external initializer {
        address sender = _msgSender();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __SignatureVerifier_init(name_, version_, threshold_);
        _grantRole(SIGNER_ROLE, signer_);
        _grantRole(OPERATOR_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
    }

    function admin() public view override returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function changeAdmin(address newAdmin_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin_);
    }

    function setThreshhold(uint8 threshold_) external onlyRole(OPERATOR_ROLE) {
        _setThreshhold(threshold_);
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
