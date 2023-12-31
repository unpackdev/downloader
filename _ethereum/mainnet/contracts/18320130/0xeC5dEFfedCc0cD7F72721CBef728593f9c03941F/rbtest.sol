// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: rb test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    nothing to be seen here    //
//                               //
//                               //
///////////////////////////////////


contract rbtest is ERC721Creator {
    constructor() ERC721Creator("rb test", "rbtest") {}
}
