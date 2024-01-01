// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Desktops
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Spøgelsesmaskinen    //
//    The Desktops         //
//                         //
//                         //
/////////////////////////////


contract DESKTOP is ERC721Creator {
    constructor() ERC721Creator("The Desktops", "DESKTOP") {}
}
