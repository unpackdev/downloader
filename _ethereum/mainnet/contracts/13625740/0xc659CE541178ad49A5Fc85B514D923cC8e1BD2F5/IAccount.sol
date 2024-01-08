//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

struct Transaction {
    address to;
    uint256 value;
    bytes data;
}

interface IAccount {
    function execute(Transaction calldata transaction) external payable;

    function batchExecute(Transaction[] calldata transactions) external payable;

    function owner() external view returns (address);
}
