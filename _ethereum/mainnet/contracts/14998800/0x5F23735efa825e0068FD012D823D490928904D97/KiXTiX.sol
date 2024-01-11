
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KixTix
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//     +-+-+-+ +-+-+-+      //
//     |K|I|X| |T|I|X|      //
//     +-+-+-+ +-+-+-+      //
//     +-+-+                //
//     |b|y|                //
//     +-+-+                //
//     +-+-+-+ +-+-+-+-+    //
//     |K|I|X| |L|I|N|K|    //
//     +-+-+-+ +-+-+-+-+    //
//                          //
//                          //
//////////////////////////////


contract KiXTiX is ERC721Creator {
    constructor() ERC721Creator("KixTix", "KiXTiX") {}
}
