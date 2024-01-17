
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: frnvrs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    hello world    //
//                   //
//                   //
///////////////////////


contract frnvrs is ERC721Creator {
    constructor() ERC721Creator("frnvrs", "frnvrs") {}
}
