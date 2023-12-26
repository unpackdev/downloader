// Copyright (C) 2023 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.21;

interface IOwnable {
    /**
     * @notice Indicates update of the pending owner address
     * @param oldPendingOwner Old pending owner
     * @param newPendingOwner New pending owner
     */
    event PendingOwnerSet(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    /**
     * @notice Indicates update of the owner address
     * @param oldOwner Old contract's owner
     * @param newOwner New contract's owner
     */
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    /**
     * @notice Sets pending owner to the `newPendingOwner` address
     * @param newPendingOwner Address of new pending owner
     * @dev The function is callable only by the owner, emits PendingOwnerSet event
     */
    function setPendingOwner(address newPendingOwner) external;

    /**
     * @notice Sets owner to the pending owner address
     * @dev The function is callable only by the pending owner, emits OwnerSet event
     */
    function setOwner() external;

    /**
     * @notice Returns current owner address
     * @return currentOwner Owner of the contract
     */
    function getOwner() external view returns (address currentOwner);

    /**
     * @notice Returns current pending owner address
     * @return currentPendingOwner Pending owner of the contract
     */
    function getPendingOwner()
        external
        view
        returns (address currentPendingOwner);
}
