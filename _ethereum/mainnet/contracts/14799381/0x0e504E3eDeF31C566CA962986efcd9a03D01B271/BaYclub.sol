
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bitchy ape yolo club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    High Ape Society    //
//                        //
//                        //
////////////////////////////


contract BaYclub is ERC721Creator {
    constructor() ERC721Creator("Bitchy ape yolo club", "BaYclub") {}
}
