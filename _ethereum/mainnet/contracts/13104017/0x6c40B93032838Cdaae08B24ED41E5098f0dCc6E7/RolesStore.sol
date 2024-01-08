// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE */

struct Role {
    mapping (address => bool) bearer;
    uint256 numberOfBearers;
}