
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tasty Bones
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Tasty Bones    //
//                   //
//                   //
///////////////////////


contract TABO is ERC721Creator {
    constructor() ERC721Creator("Tasty Bones", "TABO") {}
}
