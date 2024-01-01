// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Abstract Wojak
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    xxxWojakxxx    //
//                   //
//                   //
///////////////////////


contract TAW is ERC721Creator {
    constructor() ERC721Creator("The Abstract Wojak", "TAW") {}
}
