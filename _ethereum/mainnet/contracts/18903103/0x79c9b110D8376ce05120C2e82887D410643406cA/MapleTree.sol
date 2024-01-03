// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Red Leaves
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    🍁    //
//          //
//          //
//////////////


contract MapleTree is ERC721Creator {
    constructor() ERC721Creator("Red Leaves", "MapleTree") {}
}
