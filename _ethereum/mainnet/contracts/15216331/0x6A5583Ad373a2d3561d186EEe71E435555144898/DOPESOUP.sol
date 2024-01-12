
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DOPE SOUP
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//    ·▄▄▄▄         ▄▄▄·▄▄▄ .    .▄▄ ·       ▄• ▄▌ ▄▄▄·          //
//    ██▪ ██ ▪     ▐█ ▄█▀▄.▀·    ▐█ ▀. ▪     █▪██▌▐█ ▄█          //
//    ▐█· ▐█▌ ▄█▀▄  ██▀·▐▀▀▪▄    ▄▀▀▀█▄ ▄█▀▄ █▌▐█▌ ██▀·          //
//    ██. ██ ▐█▌.▐▌▐█▪·•▐█▄▄▌    ▐█▄▪▐█▐█▌.▐▌▐█▄█▌▐█▪·•          //
//    ▀▀▀▀▀•  ▀█▄▀▪.▀    ▀▀▀      ▀▀▀▀  ▀█▄▀▪ ▀▀▀ .▀             //
//                                                               //
//    a distinctive collection of what a noodle soup could be    //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract DOPESOUP is ERC721Creator {
    constructor() ERC721Creator("DOPE SOUP", "DOPESOUP") {}
}
