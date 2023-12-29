// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

interface IReservoir {
    struct ExecutionInfo {
        address module;
        bytes data;
        uint256 value;
    }

    function execute(ExecutionInfo[] calldata _executionInfos) external payable;
}
