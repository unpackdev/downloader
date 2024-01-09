
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SUPERGUCCI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    SUPERGUCCI    //
//                  //
//                  //
//////////////////////


contract GUCCI is ERC721Creator {
    constructor() ERC721Creator("SUPERGUCCI", "GUCCI") {}
}
