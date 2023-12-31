// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BB's Ailis Fanart
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Fanarts for Ailis by Izumo!    //
//                                   //
//                                   //
///////////////////////////////////////


contract BAILis is ERC721Creator {
    constructor() ERC721Creator("BB's Ailis Fanart", "BAILis") {}
}
