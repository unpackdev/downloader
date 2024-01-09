
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: On Chain Monkey Dessert
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    OnChainMonkey Dessert    //
//                             //
//                             //
/////////////////////////////////


contract OCMD is ERC721Creator {
    constructor() ERC721Creator("On Chain Monkey Dessert", "OCMD") {}
}
