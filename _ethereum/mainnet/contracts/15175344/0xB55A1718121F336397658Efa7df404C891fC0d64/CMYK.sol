
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CMYK
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    █─▄▄▄─█▄─▀█▀─▄█▄─█─▄█▄─█─▄█    //
//    █─███▀██─█▄█─███▄─▄███─▄▀██    //
//    ▀▄▄▄▄▄▀▄▄▄▀▄▄▄▀▀▄▄▄▀▀▄▄▀▄▄▀    //
//                                   //
//                                   //
///////////////////////////////////////


contract CMYK is ERC721Creator {
    constructor() ERC721Creator("CMYK", "CMYK") {}
}
