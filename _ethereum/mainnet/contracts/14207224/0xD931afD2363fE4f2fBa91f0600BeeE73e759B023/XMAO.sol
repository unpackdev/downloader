
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: xiaomaogy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    from xiaomaogy    //
//                      //
//                      //
//////////////////////////


contract XMAO is ERC721Creator {
    constructor() ERC721Creator("xiaomaogy", "XMAO") {}
}
