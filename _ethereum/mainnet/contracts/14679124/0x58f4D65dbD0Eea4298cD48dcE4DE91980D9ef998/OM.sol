
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Otherside Meta
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    Otherside Meta    //
//                      //
//                      //
//////////////////////////


contract OM is ERC721Creator {
    constructor() ERC721Creator("Otherside Meta", "OM") {}
}
