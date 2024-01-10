
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DSMShrimp
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//     ______        //
//    /\  ___\       //
//    \ \  __\       //
//     \ \_____\     //
//      \/_____/     //
//                   //
//                   //
///////////////////////


contract SHRIMP is ERC721Creator {
    constructor() ERC721Creator("DSMShrimp", "SHRIMP") {}
}
