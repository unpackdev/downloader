// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tears in the Rain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Tears in the Rain    //
//                         //
//                         //
/////////////////////////////


contract TITR is ERC721Creator {
    constructor() ERC721Creator("Tears in the Rain", "TITR") {}
}
