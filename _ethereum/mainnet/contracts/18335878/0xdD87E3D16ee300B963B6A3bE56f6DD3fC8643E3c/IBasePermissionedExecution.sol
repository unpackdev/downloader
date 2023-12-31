// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreAccessControlV1.sol";

interface IBasePermissionedExecution is ICoreAccessControlV1 {
    function executeOperation(address target, bytes calldata payload) external payable;
}
