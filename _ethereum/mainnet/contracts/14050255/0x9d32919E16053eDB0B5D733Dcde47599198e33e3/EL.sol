
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EdoLena
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    EDOLENALINE    //
//                   //
//                   //
///////////////////////


contract EL is ERC721Creator {
    constructor() ERC721Creator("EdoLena", "EL") {}
}
