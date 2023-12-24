// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hedy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    hedylamar    //
//                 //
//                 //
/////////////////////


contract HDY is ERC721Creator {
    constructor() ERC721Creator("Hedy", "HDY") {}
}
