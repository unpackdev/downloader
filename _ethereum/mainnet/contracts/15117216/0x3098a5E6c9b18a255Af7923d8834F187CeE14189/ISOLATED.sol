
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Isolated Stories
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    ISOLATED STORIES | In Black & White    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract ISOLATED is ERC721Creator {
    constructor() ERC721Creator("Isolated Stories", "ISOLATED") {}
}
