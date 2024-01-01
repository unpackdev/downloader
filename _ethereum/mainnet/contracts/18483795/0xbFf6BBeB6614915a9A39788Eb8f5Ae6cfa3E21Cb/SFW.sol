// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shibairo Fanart Works
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    FAN v(^^)v    //
//                  //
//                  //
//////////////////////


contract SFW is ERC721Creator {
    constructor() ERC721Creator("Shibairo Fanart Works", "SFW") {}
}
