// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Initializable.sol";
import "./IAdminStructure.sol";

/// @title An admin manager
/// @notice Manages the administrators by allowing the addition and removal of admins
contract AdminStructure is Initializable {
    /// @dev Address of the SuperAdmin contract
    ISuperAdmin public superAdminContract;
    /// @dev List of admin addresses
    address[] private adminList;
    /// @dev Mapping to track admin status of addresses
    mapping(address => bool) public isAdmin;

    /// @dev Event emitted when an address is added as an admin
    event AddedAdmin(address admin);
    /// @dev Event emitted when an address is removed from the admin list
    event RemovedAdmin(address admin);

    /// @notice Initializes the AdminStructure contract with the SuperAdmin contract address
    /// @param _superAdminContract The address of the SuperAdmin contract
    function initialize(ISuperAdmin _superAdminContract) external initializer {
        superAdminContract = _superAdminContract;
    }

    /// @dev Throws an error if the caller is not the super admin
    modifier onlySuperAdmin() {
        isValidSuperAdmin(msg.sender);
        _;
    }

    /// @dev Throws an error if the caller is not the super admin or an admin
    modifier onlyAdmin(address caller) {
        require(caller == superAdmin() || isAdmin[caller], "NotUserAdmin");
        _;
    }

    /// @notice Adds multiple addresses as admins
    /// @param _admins The addresses to be added as admins
    function addAdmins(address[] calldata _admins) external onlySuperAdmin {
        for (uint256 i; i < _admins.length; i++) {
            require(!isAdmin[_admins[i]], "DuplicateAdmin");
            isAdmin[_admins[i]] = true;
            adminList.push(_admins[i]);
            emit AddedAdmin(_admins[i]);
        }
    }

    /// @notice Removes multiple addresses from the admin list
    /// @param _admins The addresses to be removed from the admin list
    function removeAdmins(address[] calldata _admins) external onlySuperAdmin {
        for (uint i = 0; i < _admins.length; i++) {
            for (uint j = 0; j < adminList.length; j++) {
                if (_admins[i] == adminList[j]) {
                    // Remove the matching admin address from the list
                    adminList[j] = adminList[adminList.length - 1];
                    adminList.pop();
                    delete isAdmin[_admins[i]];
                    emit RemovedAdmin(_admins[i]);
                    break;
                }
            }
        }
    }

    /// @notice Retrieves all the admin addresses
    /// @return An array of admin addresses
    function getAllAdmins() external view returns (address[] memory) {
        return adminList;
    }

    /// @notice Checks if the caller is a valid admin
    /// @param caller The address of the caller
    function isValidAdmin(address caller) external view onlyAdmin(caller) {}

    /// @notice Returns the address of the current super admin
    /// @return The address of the super admin
    function superAdmin() public view returns (address) {
        return superAdminContract.superAdmin();
    }

    /// @notice Checks if the caller is a valid super admin
    /// @param caller The address of the caller
    function isValidSuperAdmin(address caller) public view {
        superAdminContract.isValidSuperAdmin(caller);
    }

    uint256[60] private __gap;
}
