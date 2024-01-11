
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: speculum
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    paperthin    //
//                 //
//                 //
/////////////////////


contract spec is ERC721Creator {
    constructor() ERC721Creator("speculum", "spec") {}
}
