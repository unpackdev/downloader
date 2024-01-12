
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: digital artwork
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    3D digital artwork everyday from home     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract DA is ERC721Creator {
    constructor() ERC721Creator("digital artwork", "DA") {}
}
