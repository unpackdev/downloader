// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Community
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    GIBTOKEN    //
//                //
//                //
////////////////////


contract GIB is ERC721Creator {
    constructor() ERC721Creator("Community", "GIB") {}
}
