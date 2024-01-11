
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Careless and Well-Intentioned by Tyler Hobbs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    -----------------------    //
//     T Y L E R X H O B B S     //
//    -----------------------    //
//                               //
//                               //
///////////////////////////////////


contract CAWI is ERC721Creator {
    constructor() ERC721Creator("Careless and Well-Intentioned by Tyler Hobbs", "CAWI") {}
}
