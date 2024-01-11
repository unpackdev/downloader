
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANIME
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ///////////////////////////    //
//    //                       //    //
//    //                       //    //
//    //    +-++-++-++-++-+    //    //
//    //    |A||N||I||M||E|    //    //
//    //    +-++-++-++-++-+    //    //
//    //     Anime Token ®     //    //
//    //                       //    //
//    //                       //    //
//    ///////////////////////////    //
//                                   //
//                                   //
///////////////////////////////////////


contract ANIME is ERC721Creator {
    constructor() ERC721Creator("ANIME", "ANIME") {}
}
