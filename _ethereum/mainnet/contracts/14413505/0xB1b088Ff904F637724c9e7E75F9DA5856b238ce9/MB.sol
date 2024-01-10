
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metroverse Blackout
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Metroverse Blackout    //
//                           //
//                           //
///////////////////////////////


contract MB is ERC721Creator {
    constructor() ERC721Creator("Metroverse Blackout", "MB") {}
}
