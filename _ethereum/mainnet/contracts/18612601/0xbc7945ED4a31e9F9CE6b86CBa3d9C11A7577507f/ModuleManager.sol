// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Cyan Wallet Module Manager Storage - A Cyan wallet's module manager's storage.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
abstract contract ModuleManagerStorage {
    /// @notice Storing allowed contract methods.
    ///     Note: Target Contract Address => Sighash of method => Module address
    mapping(address => mapping(bytes4 => address)) internal _modules;

    /// @notice Storing internally allowed module methods.
    ///     Note: Sighash of module method => Module address
    mapping(bytes4 => address) internal _internalModules;
}

/// @title Cyan Wallet Module Manager - A Cyan wallet's module manager's functionalities.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
abstract contract IModuleManager is ModuleManagerStorage {
    event SetModule(address target, bytes4 funcHash, address oldModule, address newModule);
    event SetInternalModule(bytes4 funcHash, address oldModule, address newModule);

    /// @notice Sets the handler module of the target's function.
    /// @param target Address of the target contract.
    /// @param funcHash Sighash of the target contract's method.
    /// @param module Address of the handler module.
    function setModule(
        address target,
        bytes4 funcHash,
        address module
    ) external virtual;

    /// @notice Returns a handling module of the target function.
    /// @param target Address of the target contract.
    /// @param funcHash Sighash of the target contract's method.
    /// @return module Handler module.
    function getModule(address target, bytes4 funcHash) external view returns (address) {
        return _modules[target][funcHash];
    }

    /// @notice Sets the internal handler module of the function.
    /// @param funcHash Sighash of the module method.
    /// @param module Address of the handler module.
    function setInternalModule(bytes4 funcHash, address module) external virtual;

    /// @notice Returns an internal handling module of the given function.
    /// @param funcHash Sighash of the module's method.
    /// @return module Handler module.
    function getInternalModule(bytes4 funcHash) external view returns (address) {
        return _internalModules[funcHash];
    }

    /// @notice Used to call module functions on the wallet.
    ///     Usually used to call locking function of the module on the wallet.
    /// @param data Data payload of the transaction.
    /// @return Result of the execution.
    function executeModule(bytes memory data) external virtual returns (bytes memory);
}
