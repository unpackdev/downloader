// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

interface INativeVault {
    function collect() external payable;
    function returnFunds() external payable;
}