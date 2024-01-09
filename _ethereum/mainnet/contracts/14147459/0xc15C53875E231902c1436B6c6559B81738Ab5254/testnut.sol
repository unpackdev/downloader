
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test in a nutshell
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    TEST IN A NUTSHELL    //
//                          //
//                          //
//////////////////////////////


contract testnut is ERC721Creator {
    constructor() ERC721Creator("Test in a nutshell", "testnut") {}
}
