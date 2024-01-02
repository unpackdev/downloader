// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IAddressRegistry {
    function addEntry(address, address) external;
    function getEntry(address) external returns (address);
}
