
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beenzino
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Beenzino    //
//                //
//                //
////////////////////


contract Beenzino is ERC721Creator {
    constructor() ERC721Creator("Beenzino", "Beenzino") {}
}
