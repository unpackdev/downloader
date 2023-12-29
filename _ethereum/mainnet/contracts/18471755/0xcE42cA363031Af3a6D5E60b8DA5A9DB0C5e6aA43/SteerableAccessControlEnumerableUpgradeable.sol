// SPDX-License-Identifier: MIT
// Copyright (c) 2023 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract SteerableAccessControlEnumerableUpgradeable is AccessControlEnumerableUpgradeable {
    /// @notice The default role intended to perform access-restricted actions.
    /// @dev We are using this instead of DEFAULT_ADMIN_ROLE because the latter
    /// is intended to grant/revoke roles and will be secured differently.
    bytes32 public constant DEFAULT_STEERING_ROLE = keccak256("DEFAULT_STEERING_ROLE");
}
