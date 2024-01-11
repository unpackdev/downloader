
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KabuKalo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    KabuKalo 10000    //
//                      //
//                      //
//////////////////////////


contract KBKL is ERC721Creator {
    constructor() ERC721Creator("KabuKalo", "KBKL") {}
}
