
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kol
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    new generation nft     //
//                           //
//                           //
///////////////////////////////


contract kl is ERC721Creator {
    constructor() ERC721Creator("kol", "kl") {}
}
