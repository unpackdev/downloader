// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colorful Box
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Commemorative Illustration    //
//                                  //
//                                  //
//////////////////////////////////////


contract CBOX is ERC721Creator {
    constructor() ERC721Creator("Colorful Box", "CBOX") {}
}
