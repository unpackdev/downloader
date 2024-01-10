
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beanz Official
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Beanz Official    //
//                      //
//                      //
//////////////////////////


contract BEANZ is ERC721Creator {
    constructor() ERC721Creator("Beanz Official", "BEANZ") {}
}
