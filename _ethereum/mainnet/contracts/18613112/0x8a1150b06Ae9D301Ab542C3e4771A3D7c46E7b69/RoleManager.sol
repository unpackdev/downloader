// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Cyan Wallet Role Manager - A Cyan wallet's role manager's storage.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
abstract contract RoleManagerStorage {
    address[3] internal _deprecatedOperators; // Deprecated
    address internal _admin;
    address internal _owner;
    mapping(address => bool) internal _operators;
}

/// @title Cyan Wallet Role Manager - A Cyan wallet's role manager's functionalities.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
abstract contract IRoleManager is RoleManagerStorage {
    event SetOwner(address owner);
    event SetAdmin(address admin);
    event SetOperator(address operator, bool isActive);

    modifier onlyOperator() {
        _checkOnlyOperator();
        _;
    }

    modifier onlyAdmin() {
        _checkOnlyAdmin();
        _;
    }

    modifier onlyOwner() {
        _checkOnlyOwner();
        _;
    }

    constructor(address admin) {
        require(admin != address(0x0), "Invalid admin address.");
        _admin = admin;
    }

    /// @notice Returns current owner of the wallet.
    /// @return Address of the current owner.
    function getOwner() external view virtual returns (address);

    /// @notice Changes the current admin.
    /// @param admin New admin address.
    function setAdmin(address admin) external virtual;

    /// @notice Returns current admin of the core contract.
    /// @return Address of the current admin.
    function getAdmin() external view virtual returns (address);

    /// @notice Sets the operator status.
    /// @param operator Operator address.
    /// @param isActive Is active or not.
    function setOperator(address operator, bool isActive) external virtual;

    /// @notice Checks whether the given address is an operator.
    /// @param operator Address that will be checked.
    /// @return result Boolean result.
    function isOperator(address operator) external view virtual returns (bool result);

    /// @notice Checks whether the message sender is an operator.
    function _checkOnlyOperator() internal view virtual;

    /// @notice Checks whether the message sender is an admin.
    function _checkOnlyAdmin() internal view virtual;

    /// @notice Checks whether the message sender is an owner.
    function _checkOnlyOwner() internal view virtual;
}
