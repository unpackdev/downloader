// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RoleAware.sol";

abstract contract Executor is RoleAware {
    function requiredRoles() external virtual returns (uint256[] memory);

    function execute() external virtual;
}
