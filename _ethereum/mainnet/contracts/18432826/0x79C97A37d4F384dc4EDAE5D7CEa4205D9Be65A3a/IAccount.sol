// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAccount {
    function execute(address adapter, bytes calldata data, uint256 ethToSend)
        external
        payable
        returns (bytes memory returnData);
}
