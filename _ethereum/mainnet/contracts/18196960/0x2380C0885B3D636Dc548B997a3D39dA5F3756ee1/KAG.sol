// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kawaii Anime Girls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Please find a kawaii girl.    //
//                                  //
//                                  //
//////////////////////////////////////


contract KAG is ERC721Creator {
    constructor() ERC721Creator("Kawaii Anime Girls", "KAG") {}
}
