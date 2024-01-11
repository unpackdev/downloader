
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Buy it or I'll put it inside
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    Girls say things when they are angry and do certain things. Funny    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract BiPii is ERC721Creator {
    constructor() ERC721Creator("Buy it or I'll put it inside", "BiPii") {}
}
