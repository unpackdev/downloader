
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WMPTest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract WMPT is ERC721Creator {
    constructor() ERC721Creator("WMPTest", "WMPT") {}
}
