
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lyrical—Code™
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    One lyric at a time.    //
//                            //
//                            //
////////////////////////////////


contract LYRIC is ERC721Creator {
    constructor() ERC721Creator(unicode"Lyrical—Code™", "LYRIC") {}
}
