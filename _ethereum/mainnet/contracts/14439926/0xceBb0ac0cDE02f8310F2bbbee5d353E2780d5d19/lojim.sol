
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lojim
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    I don't iron know art    //
//                             //
//                             //
/////////////////////////////////


contract lojim is ERC721Creator {
    constructor() ERC721Creator("lojim", "lojim") {}
}
