// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IOperatorLocker {
    function operatorIsLocked(uint256 _level, address _operator) external view returns (bool);
}