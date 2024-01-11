
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: P0lleywally
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    P0lleyWally    //
//                   //
//                   //
///////////////////////


contract P0W is ERC721Creator {
    constructor() ERC721Creator("P0lleywally", "P0W") {}
}
