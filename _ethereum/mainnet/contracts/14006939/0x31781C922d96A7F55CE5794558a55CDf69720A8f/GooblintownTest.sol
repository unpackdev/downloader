
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GooblinTownTest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Gooblintown    //
//                   //
//                   //
///////////////////////


contract GooblintownTest is ERC721Creator {
    constructor() ERC721Creator("GooblinTownTest", "GooblintownTest") {}
}
