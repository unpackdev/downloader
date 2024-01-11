
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mirror Passes V2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Mirror Passes V2    //
//                        //
//                        //
////////////////////////////


contract Mirror is ERC721Creator {
    constructor() ERC721Creator("Mirror Passes V2", "Mirror") {}
}
