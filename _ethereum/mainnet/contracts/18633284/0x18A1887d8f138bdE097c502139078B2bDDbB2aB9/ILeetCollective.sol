// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ILeetCollective {
    function nameOf(address member) external view returns (string memory);

    function roleOf(address member) external view returns (uint16);

    function roleNameOf(address member) external view returns (string memory);
}
