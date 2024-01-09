// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AccessControlEnumerable.sol";

abstract contract Manageable is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
}