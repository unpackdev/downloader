// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AIbstractions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//    .▄▄ · ▄• ▄▌ ▐ ▄  ▄▄▄·  ▄▄ • ▄▄▄ .    //
//    ▐█ ▀. █▪██▌•█▌▐█▐█ ▀█ ▐█ ▀ ▪▀▄.▀·    //
//    ▄▀▀▀█▄█▌▐█▌▐█▐▐▌▄█▀▀█ ▄█ ▀█▄▐▀▀▪▄    //
//    ▐█▄▪▐█▐█▄█▌██▐█▌▐█ ▪▐▌▐█▄▪▐█▐█▄▄▌    //
//     ▀▀▀▀  ▀▀▀ ▀▀ █▪ ▀  ▀ ·▀▀▀▀  ▀▀▀     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract AIBS is ERC721Creator {
    constructor() ERC721Creator("AIbstractions", "AIBS") {}
}
