// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IRegistry {
    function isValid(address handler) external view returns (bool result);
}
