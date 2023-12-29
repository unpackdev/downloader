// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jasonday
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    the study of one's self    //
//                               //
//                               //
///////////////////////////////////


contract self is ERC721Creator {
    constructor() ERC721Creator("jasonday", "self") {}
}
