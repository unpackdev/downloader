// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DelegateCallManager.sol";
import "./RoleManager.sol";
import "./ModuleManager.sol";

/// @title Cyan Wallet Core Storage - A Cyan wallet's core storage features.
/// @dev This contract must be the very first parent of the Core contract and Module contracts.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
abstract contract ICoreStorage is DelegateCallManager, IRoleManager, IModuleManager {
    constructor(address admin) IRoleManager(admin) {
        require(admin != address(0x0), "Invalid admin address.");
    }

    /// @inheritdoc IModuleManager
    function setModule(
        address target,
        bytes4 funcHash,
        address module
    ) external override noDelegateCall onlyAdmin {
        emit SetModule(target, funcHash, _modules[target][funcHash], module);
        _modules[target][funcHash] = module;
    }

    /// @inheritdoc IModuleManager
    function setInternalModule(bytes4 funcHash, address module) external override noDelegateCall onlyAdmin {
        emit SetInternalModule(funcHash, _internalModules[funcHash], module);
        _internalModules[funcHash] = module;
    }

    /// @inheritdoc IRoleManager
    function getOwner() external view override onlyDelegateCall returns (address) {
        return _owner;
    }

    /// @inheritdoc IRoleManager
    function setAdmin(address admin) external override noDelegateCall onlyAdmin {
        require(admin != address(0x0), "Invalid admin address.");
        _admin = admin;
        emit SetAdmin(admin);
    }

    /// @inheritdoc IRoleManager
    function getAdmin() external view override noDelegateCall returns (address) {
        return _admin;
    }

    /// @inheritdoc IRoleManager
    function setOperator(address operator, bool isActive) external override noDelegateCall onlyAdmin {
        require(operator != address(0x0), "Invalid operator address.");
        _operators[operator] = isActive;
        emit SetOperator(operator, isActive);
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyAdmin() internal view override {
        if (address(this) != _this) {
            require(ICoreStorage(_this).getAdmin() == msg.sender, "Caller is not an admin.");
        } else {
            require(_admin == msg.sender, "Caller is not an admin.");
        }
    }

    /// @inheritdoc IRoleManager
    function isOperator(address operator) external view override noDelegateCall returns (bool result) {
        return _operators[operator];
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyOperator() internal view override {
        require(ICoreStorage(_this).isOperator(msg.sender), "Caller is not an operator.");
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyOwner() internal view override {
        require(_owner == msg.sender, "Caller is not an owner.");
    }
}
