// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IResolver {
    function getProcessableOrders()
        external
        returns (bool canExec, bytes memory execPayload);
}
