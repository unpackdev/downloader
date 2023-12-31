// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HIKO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    Hiko    //
//            //
//            //
////////////////


contract HIKO is ERC721Creator {
    constructor() ERC721Creator("HIKO", "HIKO") {}
}
