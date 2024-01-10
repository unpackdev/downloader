// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

enum Base {
    Maple,
    Sunken,
    Oak,
    Teak,
    Black,
    Blue,
    Cherry,
    Turtle
}

struct TraitSet {
    Base base;
    uint8 flags;
    uint8 gilding;
    uint16 health;
    uint8 sails;
    uint16 speed;
    uint8 tier;
}
