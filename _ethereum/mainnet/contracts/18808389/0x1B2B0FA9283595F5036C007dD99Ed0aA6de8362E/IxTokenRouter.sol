// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IxTokenRouter {
    function getXToken(string memory _name) external view returns (address);
    function getCToken(string memory _name) external view returns (address);
}