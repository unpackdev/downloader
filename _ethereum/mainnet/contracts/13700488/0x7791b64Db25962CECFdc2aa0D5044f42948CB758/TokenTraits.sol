// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

struct TokenTraits {
    /// @dev every initialised token should have this as true
    /// this is just used to check agains a non-initialized struct
    bool exists;
    bool isVampire;
    // Shared Traits
    uint8 skin;
    uint8 face;
    uint8 clothes;
    // Human-only Traits
    uint8 pants;
    uint8 boots;
    uint8 accessory;
    uint8 hair;
    // Vampire-only Traits
    uint8 cape;
    uint8 predatorIndex;
}