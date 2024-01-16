
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark demons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//    +---------------------------------------------+    //
//    | This NFT was created by Mary and only by me |    //
//    +---------------------------------------------+    //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract DD is ERC721Creator {
    constructor() ERC721Creator("Dark demons", "DD") {}
}
