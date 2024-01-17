
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: loki to the moon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    loki to the moon    //
//                        //
//                        //
////////////////////////////


contract loki is ERC721Creator {
    constructor() ERC721Creator("loki to the moon", "loki") {}
}
