
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Living Examples Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Living Examples Art    //
//                           //
//    Performative NFTs      //
//                           //
//                           //
///////////////////////////////


contract LEA is ERC721Creator {
    constructor() ERC721Creator("Living Examples Art", "LEA") {}
}
