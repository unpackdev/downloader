// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Administrated.sol";

/**
 * @title Managed
 *
 * @dev Contract provides a basic access control mechanism for Manager role.
 * The contract also includes control of access rights for Admin and Manager roles both.
 */
abstract contract Managed is Initializable, Administrated {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event AddManager(address indexed manager, address indexed admin);
    event RemoveManager(address indexed manager, address indexed admin);

    EnumerableSetUpgradeable.AddressSet internal managers;

    /**
     * @dev Throws if called by any account other than the admin or manager.
     */
    modifier onlyAdminOrManager() {
        require(
            isAdmin(msg.sender) || isManager(msg.sender),
            "Managered: sender is not admin or manager"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(isManager(msg.sender), "Managered: sender is not manager");
        _;
    }

    /**
     * @dev Checks if an account is manager.
     * @param _manager The address of manager account to check.
     */
    function isManager(address _manager) public view returns (bool) {
        return managers.contains(_manager);
    }

    /**
     * @dev Returns count of added managers accounts.
     */
    function getManagerCount() external view returns (uint256) {
        return managers.length();
    }

    /**
     * @dev Allows the admin to add manager account.
     *
     * Emits a {AddManager} event with `manager` set to new added manager address
     * and `admin` to who added it.
     *
     * @param _manager The address of manager account to add.
     */
    function addManager(address _manager) external onlyAdmin {
        managers.add(_manager);
        emit AddManager(_manager, msg.sender);
    }

    /**
     * @dev Allows the admin to remove manager account.
     *
     * Emits a {removeManager} event with `manager` set to removed manager address
     * and `admin` to who removed it.
     *
     * @param _manager The address of manager account to remove.
     */
    function removeManager(address _manager) external onlyAdmin {
        managers.remove(_manager);
        emit RemoveManager(_manager, msg.sender);
    }
}
