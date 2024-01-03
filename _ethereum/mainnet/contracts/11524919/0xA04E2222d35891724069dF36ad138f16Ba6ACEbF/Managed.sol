/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Administrated.sol";

/**
 * @title Managed
 *
 * @dev Contract provides a basic access control mechanism for Manager role.
 * The contract also includes control of access rights for Admin and Manager roles both.
 */
contract Managed is Initializable, Administrated {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddManager(address indexed manager, address indexed admin);
    event RemoveManager(address indexed manager, address indexed admin);

    EnumerableSet.AddressSet internal managers;

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
