// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PIRATE81
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//    +-+-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+-+-+    //
//    |i|n|f|i|n|i|t|y| |b|y| |p|i|r|a|t|e|8|1|    //
//    +-+-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+-+-+    //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract PRT81 is ERC721Creator {
    constructor() ERC721Creator("PIRATE81", "PRT81") {}
}
