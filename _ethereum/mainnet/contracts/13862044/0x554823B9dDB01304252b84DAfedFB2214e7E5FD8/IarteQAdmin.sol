/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <kam@arteq.io> <kam@2b.team> <kam.cpp@gmail.com>
/// @title The interface of the admin contract controlling all other artèQ smart contracts
interface IarteQAdmin is IarteQTaskFinalizer {

    event TaskCreated(address creatorAdmin, uint256 taskId, string detailsURI);
    event TaskApproved(address approverAdmin, uint256 taskId);
    event TaskApprovalCancelled(address cancellerAdmin, uint256 taskId);
    event FinalizerAdded(address granter, address newFinalizer);
    event FinalizerRemoved(address revoker, address removedFinalizer);
    event AdminAdded(address granter, address newAdmin);
    event AdminReplaced(address replacer, address removedAdmin, address replacedAdmin);
    event AdminRemoved(address revoker, address removedAdmin);
    event NewMinRequiredNrOfApprovalsSet(address setter, uint minRequiredNrOfApprovals);

    function minNrOfAdmins() external view returns (uint);
    function maxNrOfAdmins() external view returns (uint);
    function nrOfAdmins() external view returns (uint);
    function minRequiredNrOfApprovals() external view returns (uint);

    function isFinalizer(address account) external view returns (bool);
    function addFinalizer(uint256 taskId, address toBeAdded) external;
    function removeFinalizer(uint256 taskId, address toBeRemoved) external;

    function createTask(string memory detailsURI) external;
    function taskURI(uint256 taskId) external view returns (string memory);
    function approveTask(uint256 taskId) external;
    function cancelTaskApproval(uint256 taskId) external;
    function nrOfApprovals(uint256 taskId) external view returns (uint);

    function isAdmin(address account) external view returns (bool);
    function addAdmin(uint256 taskId, address toBeAdded) external;
    function replaceAdmin(uint256 taskId, address toBeRemoved, address toBeReplaced) external;
    function removeAdmin(uint256 taskId, address toBeRemoved) external;
    function setMinRequiredNrOfApprovals(uint256 taskId, uint newMinRequiredNrOfApprovals) external;
}
