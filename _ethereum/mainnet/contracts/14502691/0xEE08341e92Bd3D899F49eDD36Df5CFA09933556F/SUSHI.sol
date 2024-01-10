
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shoeshi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ¯\_(ツ)_/¯    //
//                 //
//                 //
/////////////////////


contract SUSHI is ERC721Creator {
    constructor() ERC721Creator("Shoeshi", "SUSHI") {}
}
