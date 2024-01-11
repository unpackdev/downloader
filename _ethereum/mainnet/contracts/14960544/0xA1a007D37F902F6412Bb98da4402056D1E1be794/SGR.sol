
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SG Resurrection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    +-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+    //
//    |S|G| |R|E|S|U|R|R|E|C|T|I|O|N|    //
//    +-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+    //
//                                       //
//                                       //
///////////////////////////////////////////


contract SGR is ERC721Creator {
    constructor() ERC721Creator("SG Resurrection", "SGR") {}
}
