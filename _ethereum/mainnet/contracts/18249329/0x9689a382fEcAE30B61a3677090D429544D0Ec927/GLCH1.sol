// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Glitchavites » Series I
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//     +-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+    //
//     |G|l|i|t|c|h|a|v|i|t|e|s|:| |S|e|r|i|e|s| |I|    //
//     +-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+ +-+    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract GLCH1 is ERC721Creator {
    constructor() ERC721Creator(unicode"The Glitchavites » Series I", "GLCH1") {}
}
