
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: labubu
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    labubu 31.12.2021    //
//                         //
//                         //
/////////////////////////////


contract LBB is ERC721Creator {
    constructor() ERC721Creator("labubu", "LBB") {}
}
