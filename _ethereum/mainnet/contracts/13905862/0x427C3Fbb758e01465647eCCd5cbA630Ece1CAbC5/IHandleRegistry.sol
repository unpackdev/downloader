// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IHandleRegistry {
    function mint(string memory handle, address owner) external;
}