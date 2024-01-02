// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity 0.8.17;

import "./IAccessControlEnumerable.sol";

interface IAccessController is IAccessControlEnumerable {
    error AccessDenied();

    function setupRole(bytes32 role, address account) external;

    function verifyOwner(address account) external view;
}
