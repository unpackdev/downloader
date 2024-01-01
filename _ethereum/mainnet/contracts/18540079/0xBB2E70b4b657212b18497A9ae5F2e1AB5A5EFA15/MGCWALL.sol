// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Magic Wall
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    ... dreamsDAO ...    //
//                         //
//                         //
/////////////////////////////


contract MGCWALL is ERC721Creator {
    constructor() ERC721Creator("The Magic Wall", "MGCWALL") {}
}
