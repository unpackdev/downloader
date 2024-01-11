
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HYPERA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    we don't talk about it    //
//                              //
//                              //
//////////////////////////////////


contract HYPERA is ERC721Creator {
    constructor() ERC721Creator("HYPERA", "HYPERA") {}
}
