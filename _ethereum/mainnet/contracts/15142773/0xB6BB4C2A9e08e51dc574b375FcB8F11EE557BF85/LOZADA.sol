
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOZADA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    lozada.eth    //
//                  //
//                  //
//////////////////////


contract LOZADA is ERC721Creator {
    constructor() ERC721Creator("LOZADA", "LOZADA") {}
}
