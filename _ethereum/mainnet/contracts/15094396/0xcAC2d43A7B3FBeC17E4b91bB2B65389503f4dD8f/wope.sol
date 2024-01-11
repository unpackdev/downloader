
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wope
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    wope    //
//            //
//            //
////////////////


contract wope is ERC721Creator {
    constructor() ERC721Creator("wope", "wope") {}
}
