
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOLAN APPAREL
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    NOLAN APPAREL    //
//                     //
//                     //
/////////////////////////


contract NA is ERC721Creator {
    constructor() ERC721Creator("NOLAN APPAREL", "NA") {}
}
