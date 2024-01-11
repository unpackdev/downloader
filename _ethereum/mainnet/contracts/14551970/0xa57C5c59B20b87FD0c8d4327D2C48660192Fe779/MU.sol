
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mindblowon Universe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Mindblowon Universe    //
//                           //
//                           //
//                           //
///////////////////////////////


contract MU is ERC721Creator {
    constructor() ERC721Creator("Mindblowon Universe", "MU") {}
}
