// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGenesisTypes {
    enum TokenType {
        NONE,
        GOD,
        DEMI_GOD,
        ELEMENTAL
    }

    enum TokenSubtype {
        NONE,
        CREATIVE,
        DESTRUCTIVE,
        AIR,
        EARTH,
        ELECTRICITY,
        FIRE,
        MAGMA,
        METAL,
        WATER
    }

    struct TokenTraits {
        TokenType tokenType;
        TokenSubtype tokenSubtype;
    }
}
