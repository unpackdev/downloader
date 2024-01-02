// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Songs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    (b ••)    //
//              //
//              //
//////////////////


contract SONGS is ERC721Creator {
    constructor() ERC721Creator("Songs", "SONGS") {}
}
