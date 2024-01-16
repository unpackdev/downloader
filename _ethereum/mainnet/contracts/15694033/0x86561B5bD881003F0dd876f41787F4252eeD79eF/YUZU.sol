
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yuzu Doodles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    /////////////////////////    //
//    //                     //    //
//    //                     //    //
//    //     +-++-++-++-+    //    //
//    //     |y||u||z||u|    //    //
//    //     +-++-++-++-+    //    //
//    //                     //    //
//    //                     //    //
//    /////////////////////////    //
//                                 //
//                                 //
/////////////////////////////////////


contract YUZU is ERC721Creator {
    constructor() ERC721Creator("Yuzu Doodles", "YUZU") {}
}
