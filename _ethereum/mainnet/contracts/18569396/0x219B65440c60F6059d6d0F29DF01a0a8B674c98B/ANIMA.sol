// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Animatrix
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ANIMATRIX    //
//                 //
//                 //
/////////////////////


contract ANIMA is ERC721Creator {
    constructor() ERC721Creator("Animatrix", "ANIMA") {}
}
