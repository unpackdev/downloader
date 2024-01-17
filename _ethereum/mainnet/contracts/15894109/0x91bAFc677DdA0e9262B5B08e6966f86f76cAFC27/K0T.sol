
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KINGDOM OF THIEVES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//     +-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+-+    //
//     |K|i|n|g|d|o|m| |O|f| |T|h|i|e|v|e|s|    //
//     +-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+-+    //
//                By STR4NGETHING               //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract K0T is ERC721Creator {
    constructor() ERC721Creator("KINGDOM OF THIEVES", "K0T") {}
}
