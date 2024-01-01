// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Desktop - Icons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Spøgelsesmaskinen    //
//    The Desktop          //
//    Icons                //
//                         //
//                         //
/////////////////////////////


contract ICONS is ERC721Creator {
    constructor() ERC721Creator("The Desktop - Icons", "ICONS") {}
}
