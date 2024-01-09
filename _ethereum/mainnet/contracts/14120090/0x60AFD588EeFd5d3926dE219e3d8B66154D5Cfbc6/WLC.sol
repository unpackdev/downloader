
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Weird Lil Corner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    Abandon hope all ye who enter here    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract WLC is ERC721Creator {
    constructor() ERC721Creator("Weird Lil Corner", "WLC") {}
}
