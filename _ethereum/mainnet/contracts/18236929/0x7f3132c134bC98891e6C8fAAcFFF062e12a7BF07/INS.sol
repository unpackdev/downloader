// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Infinite Inspiration
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    conte_digital    //
//                     //
//                     //
/////////////////////////


contract INS is ERC721Creator {
    constructor() ERC721Creator("Infinite Inspiration", "INS") {}
}
