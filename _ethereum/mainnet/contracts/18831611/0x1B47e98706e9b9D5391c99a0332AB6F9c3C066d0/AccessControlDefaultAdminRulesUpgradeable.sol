// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./AccessControlDefaultAdminRulesUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./IERC165.sol";
import "./IERC5313.sol";
import "./IAccessControlDefaultAdminRules.sol";
import "./IAccessControl.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./SafeCast.sol";
import "./Math.sol";

contract $AccessControlDefaultAdminRulesUpgradeable is AccessControlDefaultAdminRulesUpgradeable {
    bytes32 public constant __hh_exposed_bytecode_marker = "hardhat-exposed";

    event return$_grantRole(bool ret0);

    event return$_revokeRole(bool ret0);

    constructor() payable {
    }

    function $__AccessControlDefaultAdminRules_init(address initialDefaultAdmin) external {
        super.__AccessControlDefaultAdminRules_init(initialDefaultAdmin);
    }

    function $__AccessControlDefaultAdminRules_init_unchained(address initialDefaultAdmin) external {
        super.__AccessControlDefaultAdminRules_init_unchained(initialDefaultAdmin);
    }

    function $_grantRole(bytes32 role,address account) external returns (bool ret0) {
        (ret0) = super._grantRole(role,account);
        emit return$_grantRole(ret0);
    }

    function $_revokeRole(bytes32 role,address account) external returns (bool ret0) {
        (ret0) = super._revokeRole(role,account);
        emit return$_revokeRole(ret0);
    }

    function $_setRoleAdmin(bytes32 role,bytes32 adminRole) external {
        super._setRoleAdmin(role,adminRole);
    }

    function $_beginDefaultAdminTransfer(address newAdmin) external {
        super._beginDefaultAdminTransfer(newAdmin);
    }

    function $_cancelDefaultAdminTransfer() external {
        super._cancelDefaultAdminTransfer();
    }

    function $_acceptDefaultAdminTransfer() external {
        super._acceptDefaultAdminTransfer();
    }

    function $__AccessControl_init() external {
        super.__AccessControl_init();
    }

    function $__AccessControl_init_unchained() external {
        super.__AccessControl_init_unchained();
    }

    function $_checkRole(bytes32 role) external view {
        super._checkRole(role);
    }

    function $_checkRole(bytes32 role,address account) external view {
        super._checkRole(role,account);
    }

    function $__ERC165_init() external {
        super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        super.__ERC165_init_unchained();
    }

    function $__Context_init() external {
        super.__Context_init();
    }

    function $__Context_init_unchained() external {
        super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    function $_checkInitializing() external view {
        super._checkInitializing();
    }

    function $_disableInitializers() external {
        super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint64 ret0) {
        (ret0) = super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool ret0) {
        (ret0) = super._isInitializing();
    }

    receive() external payable {}
}
