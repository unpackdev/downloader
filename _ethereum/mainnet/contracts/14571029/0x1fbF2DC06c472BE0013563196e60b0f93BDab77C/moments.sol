
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ∞moments
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    what prevails    //
//                     //
//                     //
/////////////////////////


contract moments is ERC721Creator {
    constructor() ERC721Creator(unicode"∞moments", "moments") {}
}
