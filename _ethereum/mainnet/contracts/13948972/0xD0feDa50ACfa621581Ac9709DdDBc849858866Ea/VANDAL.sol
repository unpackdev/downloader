
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: van Dal
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Yes, I'm van Dal.    //
//                         //
//                         //
/////////////////////////////


contract VANDAL is ERC721Creator {
    constructor() ERC721Creator("van Dal", "VANDAL") {}
}
