
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ponzscheme
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Ponzscheme    //
//                  //
//                  //
//////////////////////


contract PONZ is ERC721Creator {
    constructor() ERC721Creator("Ponzscheme", "PONZ") {}
}
