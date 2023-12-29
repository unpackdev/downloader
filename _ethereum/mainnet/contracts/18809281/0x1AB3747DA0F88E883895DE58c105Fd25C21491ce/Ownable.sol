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

import "./IOwnable.sol";
import "./Errors.sol";

/**
 * @title Abstract contract with basic Ownable functionality and two-step ownership transfer
 */
abstract contract Ownable is IOwnable {
    address private pendingOwner;
    address private owner;

    modifier onlyPendingOwner() {
        address currentMsgSender = msg.sender;
        if (currentMsgSender != pendingOwner)
            revert BadMsgSender(currentMsgSender, pendingOwner);
        _;
    }

    modifier onlyOwner() {
        address currentMsgSender = msg.sender;
        if (currentMsgSender != owner)
            revert BadMsgSender(currentMsgSender, owner);
        _;
    }

    /**
     * @dev Initializes owner variable with `msg.sender` address
     */
    constructor() {
        emit OwnerSet(address(0), msg.sender);

        owner = msg.sender;
    }

    /**
     * @inheritdoc IOwnable
     */
    function setPendingOwner(
        address newPendingOwner
    ) external override onlyOwner {
        emit PendingOwnerSet(pendingOwner, newPendingOwner);

        pendingOwner = newPendingOwner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function setOwner() external override onlyPendingOwner {
        emit OwnerSet(owner, msg.sender);

        owner = msg.sender;
        delete pendingOwner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function getOwner() external view override returns (address currentOwner) {
        return owner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function getPendingOwner()
        external
        view
        override
        returns (address currentPendingOwner)
    {
        return pendingOwner;
    }
}
