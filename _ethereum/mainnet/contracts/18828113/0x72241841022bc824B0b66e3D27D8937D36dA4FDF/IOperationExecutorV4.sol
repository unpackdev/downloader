// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.22;

struct Call {
    bytes32 targetHash;
    bytes callData;
}

interface IOperationExecutorV4 {
    function executeOp(Call[] memory calls) external payable returns (bytes32);
}
