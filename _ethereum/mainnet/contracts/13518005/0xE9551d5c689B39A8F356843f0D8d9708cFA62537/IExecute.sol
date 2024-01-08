// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IExecute {
    function execute() external returns(bool success);

    function revert() external returns(bool success);
}
