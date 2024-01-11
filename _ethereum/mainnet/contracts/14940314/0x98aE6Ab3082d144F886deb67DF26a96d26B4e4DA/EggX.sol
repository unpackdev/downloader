
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EggVolutions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Hatchers    //
//                //
//                //
////////////////////


contract EggX is ERC721Creator {
    constructor() ERC721Creator("EggVolutions", "EggX") {}
}
