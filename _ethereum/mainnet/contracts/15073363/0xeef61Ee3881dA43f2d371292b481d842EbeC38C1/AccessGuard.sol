// ----------------------------------------------------------------------------
// Copyright (c) 2022 BC Technology (Hong Kong) Limited
// https://bc.group
// See LICENSE file for license details.
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./AccessControl.sol";

contract AccessGuard is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
}
