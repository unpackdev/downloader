//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Supply ABI needed from Genesis Sniper Buster
contract DeployedSupply {
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

    function getMetadataForTokenId(uint256 tokenId)
        public
        view
        returns (TokenTraits memory traits)
    {}
}
