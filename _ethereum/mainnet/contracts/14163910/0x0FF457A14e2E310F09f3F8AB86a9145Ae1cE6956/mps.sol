
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mrspants
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    mrspants    //
//                //
//                //
////////////////////


contract mps is ERC721Creator {
    constructor() ERC721Creator("mrspants", "mps") {}
}
