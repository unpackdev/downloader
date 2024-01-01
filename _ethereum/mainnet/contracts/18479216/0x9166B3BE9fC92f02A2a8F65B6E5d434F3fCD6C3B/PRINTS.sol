// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Desktop - Print editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Spøgelsesmaskinen    //
//    The Desktop          //
//    Print Editions       //
//                         //
//                         //
/////////////////////////////


contract PRINTS is ERC721Creator {
    constructor() ERC721Creator("The Desktop - Print editions", "PRINTS") {}
}
