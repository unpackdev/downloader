// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IActiveChecker {
    function isActive(address toCheck) external view returns (bool);
}
