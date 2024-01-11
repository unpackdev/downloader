
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Multis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Multis NFT contract    //
//                           //
//                           //
///////////////////////////////


contract Multis is ERC721Creator {
    constructor() ERC721Creator("Multis", "Multis") {}
}
