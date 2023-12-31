// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1/1 COLLABS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ... COLLABS ...    //
//                       //
//                       //
///////////////////////////


contract COL is ERC721Creator {
    constructor() ERC721Creator("1/1 COLLABS", "COL") {}
}
