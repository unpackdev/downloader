// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.22;

struct Call {
    bytes32 targetHash;
    bytes callData;
    bool skipped;
}

interface IOperationExecutor {
    function executeOp(Call[] memory calls, string calldata operationName) external payable;
}
