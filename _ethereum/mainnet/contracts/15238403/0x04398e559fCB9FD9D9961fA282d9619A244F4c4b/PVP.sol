
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pvp enjoyers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//    ___________    _________     //
//    ___  __ \_ |  / /__  __ \    //
//    __  /_/ /_ | / /__  /_/ /    //
//    _  ____/__ |/ / _  ____/     //
//    /_/     _____/  /_/          //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract PVP is ERC721Creator {
    constructor() ERC721Creator("pvp enjoyers", "PVP") {}
}
