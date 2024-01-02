// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Where is my owner?
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//     /\_/\     //
//    ( o.o )    //
//     > ^ <     //
//               //
//               //
///////////////////


contract CAT is ERC721Creator {
    constructor() ERC721Creator("Where is my owner?", "CAT") {}
}
