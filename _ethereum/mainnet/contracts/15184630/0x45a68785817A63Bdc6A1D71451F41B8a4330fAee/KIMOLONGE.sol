
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: キモロゲン
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    radiographics    //
//                     //
//                     //
/////////////////////////


contract KIMOLONGE is ERC721Creator {
    constructor() ERC721Creator(unicode"キモロゲン", "KIMOLONGE") {}
}
