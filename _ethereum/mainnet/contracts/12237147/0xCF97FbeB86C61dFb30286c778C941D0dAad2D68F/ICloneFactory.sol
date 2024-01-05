// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICloneFactory {
    function createClone(address target) external returns (address result);
}