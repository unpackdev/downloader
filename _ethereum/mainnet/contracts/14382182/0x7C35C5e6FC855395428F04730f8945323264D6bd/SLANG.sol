
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SLANGUAGE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//     ____ ____ ____ ____ ____ ____ ____ ____ ____     //
//    ||S |||L |||A |||N |||G |||U |||A |||G |||E ||    //
//    ||__|||__|||__|||__|||__|||__|||__|||__|||__||    //
//    |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|    //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract SLANG is ERC721Creator {
    constructor() ERC721Creator("SLANGUAGE", "SLANG") {}
}
