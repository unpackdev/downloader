
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Express Yourself
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Express Yourself     //
//                         //
//                         //
/////////////////////////////


contract EY is ERC721Creator {
    constructor() ERC721Creator("Express Yourself", "EY") {}
}
