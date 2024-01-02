// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The underworld
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    magicalords    //
//                   //
//                   //
///////////////////////


contract UW is ERC721Creator {
    constructor() ERC721Creator("The underworld", "UW") {}
}
