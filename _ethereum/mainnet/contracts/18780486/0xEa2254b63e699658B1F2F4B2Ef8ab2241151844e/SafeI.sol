// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface SafeI {
    function isOwner(address owner) external view returns (bool);
}
