// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE LAYOUT */

struct FreezableStore {
    mapping(address => bool) isFrozen;
}