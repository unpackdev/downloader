
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OVAC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Owl Visual Art Community    //
//                                //
//                                //
////////////////////////////////////


contract ovacc is ERC721Creator {
    constructor() ERC721Creator("OVAC", "ovacc") {}
}
