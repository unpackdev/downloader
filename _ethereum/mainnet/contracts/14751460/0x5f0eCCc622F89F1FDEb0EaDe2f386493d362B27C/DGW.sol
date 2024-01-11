
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digital War
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    ________  .__       .__  __         .__               __      __                           //
//    \______ \ |__| ____ |__|/  |______  |  |             /  \    /  \_____ _______             //
//     |    |  \|  |/ ___\|  \   __\__  \ |  |     ______  \   \/\/   /\__  \\_  __ \            //
//     |    `   \  / /_/  >  ||  |  / __ \|  |__  /_____/   \        /  / __ \|  | \/            //
//    /_______  /__\___  /|__||__| (____  /____/             \__/\  /  (____  /__|               //
//            \/  /_____/               \/                        \/        \/                   //
//                                                                                               //
//    Just a bunch of digital art collectibles rebelling against society and centralization.     //
//    A NFT project around property and an extraordinary community.                              //
//                                                                                               //
//    Created and featuring art by #NFTartist Schizophrenic                                      //
//    Each card is a 1/1 design focused on highlighting the artwork of Schizophrenic             //
//                                                                                               //
//    Copyright © 2022 Schizophrenic ART  |   All rights reserved                                //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract DGW is ERC721Creator {
    constructor() ERC721Creator("Digital War", "DGW") {}
}
