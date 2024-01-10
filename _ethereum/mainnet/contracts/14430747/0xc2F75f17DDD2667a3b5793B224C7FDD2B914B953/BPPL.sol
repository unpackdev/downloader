
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BeautifulPe0ple
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    BeautifulPe0ple - BPPL    //
//                              //
//                              //
//////////////////////////////////


contract BPPL is ERC721Creator {
    constructor() ERC721Creator("BeautifulPe0ple", "BPPL") {}
}
