//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IChameleon {
    struct Chameleon {
        uint16 body;
        uint16 eyes;
        uint16 background;

        // changes body color
        // 0 = solid = Veiled
        // 1 = changes colors on transfer = Metachrosis
        // 2 = animates to transparent = Camouflage
        uint8 bodyType;

        // backgroundType
        // 0 = solid = Sedentary
        // 1 = changes colors on transfer
        uint8 backgroundType;
    }
}
