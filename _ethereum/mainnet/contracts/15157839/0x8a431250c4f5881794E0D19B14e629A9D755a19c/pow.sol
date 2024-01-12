
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wiskas
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    00000000000000◄aaaaa►000000    //
//                                   //
//                                   //
///////////////////////////////////////


contract pow is ERC721Creator {
    constructor() ERC721Creator("Wiskas", "pow") {}
}
