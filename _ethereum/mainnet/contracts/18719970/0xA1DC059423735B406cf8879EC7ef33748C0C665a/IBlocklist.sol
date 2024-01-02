// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IBlocklist {
    function isBlocked(address addr) external view returns (bool);
}
