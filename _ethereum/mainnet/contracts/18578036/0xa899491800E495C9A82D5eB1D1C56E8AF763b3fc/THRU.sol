// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Throughout
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    -------->    //
//                 //
//                 //
/////////////////////


contract THRU is ERC721Creator {
    constructor() ERC721Creator("Throughout", "THRU") {}
}
