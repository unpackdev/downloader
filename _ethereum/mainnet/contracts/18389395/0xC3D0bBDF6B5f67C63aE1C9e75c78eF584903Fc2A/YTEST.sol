// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TestYYZ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    Test    //
//            //
//            //
////////////////


contract YTEST is ERC721Creator {
    constructor() ERC721Creator("TestYYZ", "YTEST") {}
}
