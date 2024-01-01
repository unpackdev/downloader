// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YURI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    YURI    //
//            //
//            //
////////////////


contract YURI is ERC721Creator {
    constructor() ERC721Creator("YURI", "YURI") {}
}
