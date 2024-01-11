
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paul Warren - Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     +-+-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+    //
//     |W|e|'|r|e| |A|l|l| |A|r|t|i|s|t|s|    //
//     +-+-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract PDWE is ERC721Creator {
    constructor() ERC721Creator("Paul Warren - Editions", "PDWE") {}
}
