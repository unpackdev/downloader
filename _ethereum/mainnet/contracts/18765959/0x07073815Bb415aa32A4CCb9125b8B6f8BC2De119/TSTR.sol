// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tester
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ---///---    //
//                 //
//                 //
/////////////////////


contract TSTR is ERC721Creator {
    constructor() ERC721Creator("Tester", "TSTR") {}
}
