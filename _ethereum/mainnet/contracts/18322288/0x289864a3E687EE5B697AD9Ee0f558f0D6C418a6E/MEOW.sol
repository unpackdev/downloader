// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEOW
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//    ,-.-.,---.,---.. . .    //
//    | | ||--- |   || | |    //
//    | | ||    |   || | |    //
//    ` ' '`---'`---'`-'-'    //
//                            //
//                            //
//                            //
////////////////////////////////


contract MEOW is ERC721Creator {
    constructor() ERC721Creator("MEOW", "MEOW") {}
}
