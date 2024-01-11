
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Folks Genesis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     +-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+    //
//     |F|O|L|K|S| |b|y| |M|E|N|S|C|H|    //
//     +-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+    //
//                                        //
//                                        //
////////////////////////////////////////////


contract FOLKS is ERC721Creator {
    constructor() ERC721Creator("Folks Genesis", "FOLKS") {}
}
