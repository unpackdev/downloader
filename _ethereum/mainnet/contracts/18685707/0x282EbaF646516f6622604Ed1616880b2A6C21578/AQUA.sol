// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AQUABLOOM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+    //
//    |J|A|N|I|E| |F|I|T|Z|G|E|R|A|L|D|    //
//    +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract AQUA is ERC721Creator {
    constructor() ERC721Creator("AQUABLOOM", "AQUA") {}
}
