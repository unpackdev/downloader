// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./ERC721.sol";

/*
    Mineral:
        0: "Topaz";
        1: "Aquamarine";
        2: "Diamond";
        3: "Emerald";
        4: "Morion";
        5: "Ruby";
        6: "Sapphire";
        7: "Amethyst";

    Cutting:
        0: "Cluster";
        1: "Octagon";
        2: "Briolette";
        3: "Cushion";
        4: "Oval";
        5: "Brilliant";
        6: "Drop";
        7: "Square";
        8: "Marquise";
        9: "Shard";
        10: "Shield";
        11: "Snowflake";
        12: "Princess";
        13: "Round";
        14: "Trilliant";
        15: "Vein";

    Translucency:
        0: "Opaque";
        1: "Semi-opaque";
        2: "Semi-transparent";
        3: "Transparent";

    Size:
        0: "1 carat";
        1: "2 carats";
        2: "3 carats";
        3: "4 carats";
        4: "5 carats";
        5: "6 carats";
        6: "7 carats";
        7: "8 carats";
*/

struct Stone {
    uint256 id;
    address owner;
    string name;

    uint8 cutting;
    uint8 mineral;
    uint8 translucency;
    uint8 size;
}

interface ICryptoStones is IERC721 {
    function getStonesProps(uint256[] calldata tokenIds) external view returns (Stone[] memory);
    function getStonesByOwner(address owner) external view returns (Stone[] memory);
}
