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

import "./EnumerableSet.sol";
import "./Ownable.sol";

/**
 * @title Administrated
 *
 * @dev Contract provides a basic access control mechanism for Admin role.
 */
contract Administrated is Initializable, OwnableUpgradeSafe {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);

    EnumerableSet.AddressSet internal admins;

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Administrated: sender is not admin");
        _;
    }

    /**
     * @dev Checks if an account is admin.
     * @param _admin The address of admin account to check.
     */
    function isAdmin(address _admin) public view returns (bool) {
        return admins.contains(_admin);
    }

    /**
     * @dev Returns count of added admins accounts.
     */
    function getAdminCount() external view returns (uint256) {
        return admins.length();
    }

    /**
     * @dev Allows the owner to add admin account.
     *
     * Emits a {AddAdmin} event with `admin` set to new added admin address.
     *
     * @param _admin The address of admin account to add.
     */
    function addAdmin(address _admin) external onlyOwner {
        admins.add(_admin);
        emit AddAdmin(_admin);
    }

    /**
     * @dev Allows the owner to remove admin account.
     *
     * Emits a {RemoveAdmin} event with `admin` set to removed admin address.
     *
     * @param _admin The address of admin account to remove.
     */
    function removeAdmin(address _admin) external onlyOwner {
        admins.remove(_admin);
        emit RemoveAdmin(_admin);
    }
}
