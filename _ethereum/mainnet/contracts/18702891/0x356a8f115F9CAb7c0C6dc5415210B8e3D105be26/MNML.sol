// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Minimals    //
//                //
//                //
////////////////////


contract MNML is ERC721Creator {
    constructor() ERC721Creator("Minimals", "MNML") {}
}
