
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Degenerate Shenanigans
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    Swimming in the pickle jar of life.    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract DGEN is ERC721Creator {
    constructor() ERC721Creator("Degenerate Shenanigans", "DGEN") {}
}
