
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sakura
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    .▄▄ ·  ▄▄▄· ▄ •▄ ▄• ▄▌▄▄▄   ▄▄▄·     //
//    ▐█ ▀. ▐█ ▀█ █▌▄▌▪█▪██▌▀▄ █·▐█ ▀█     //
//    ▄▀▀▀█▄▄█▀▀█ ▐▀▀▄·█▌▐█▌▐▀▀▄ ▄█▀▀█     //
//    ▐█▄▪▐█▐█ ▪▐▌▐█.█▌▐█▄█▌▐█•█▌▐█ ▪▐▌    //
//     ▀▀▀▀  ▀  ▀ ·▀  ▀ ▀▀▀ .▀  ▀ ▀  ▀     //
//                                         //
//                                         //
/////////////////////////////////////////////


contract SKRA is ERC721Creator {
    constructor() ERC721Creator("Sakura", "SKRA") {}
}
