// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./StorageSlot.sol";
import "./Address.sol";

import "./DelegateCallManager.sol";
import "./RoleManager.sol";
import "./ModuleManager.sol";

/// @title Cyan Wallet Core Storage - A Cyan wallet's core storage.
/// @dev This contract must be the very first parent of the Module contracts.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
abstract contract CoreStorage is RoleManagerStorage, ModuleManagerStorage {

}

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
        _modules[target][funcHash] = module;
        emit SetModule(target, funcHash, module);
    }

    /// @inheritdoc IModuleManager
    function setInternalModule(bytes4 funcHash, address module) external override noDelegateCall onlyAdmin {
        _internalModules[funcHash] = module;
        emit SetInternalModule(funcHash, module);
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
    function setOperator(uint8 index, address operator) external override noDelegateCall onlyAdmin {
        require(index < 3, "Invalid operator index.");
        require(operator != address(0x0), "Invalid operator address.");
        _operators[index] = operator;
        emit SetOperator(index, operator);
    }

    /// @inheritdoc IRoleManager
    function getOperators() external view override noDelegateCall returns (address[3] memory) {
        return _operators;
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
        assembly {
            result := or(
                or(eq(sload(_operators.slot), operator), eq(sload(add(_operators.slot, 0x1)), operator)),
                eq(sload(add(_operators.slot, 0x2)), operator)
            )
        }
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
