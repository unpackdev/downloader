
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nakamura
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    326factory    //
//                  //
//                  //
//////////////////////


contract NKFY is ERC721Creator {
    constructor() ERC721Creator("nakamura", "NKFY") {}
}
