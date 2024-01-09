
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gavin Meeler's World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Gavin Meeler's World    //
//                            //
//                            //
////////////////////////////////


contract GMW is ERC721Creator {
    constructor() ERC721Creator("Gavin Meeler's World", "GMW") {}
}
