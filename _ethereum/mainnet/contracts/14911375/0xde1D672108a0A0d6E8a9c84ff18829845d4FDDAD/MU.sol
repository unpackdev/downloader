
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MikelUrmeneta
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    MikelUrmeneta    //
//                     //
//                     //
/////////////////////////


contract MU is ERC721Creator {
    constructor() ERC721Creator("MikelUrmeneta", "MU") {}
}
