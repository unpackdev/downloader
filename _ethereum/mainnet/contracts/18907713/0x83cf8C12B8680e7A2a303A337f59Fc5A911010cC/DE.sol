// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dead ends
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    nftlisa    //
//               //
//               //
///////////////////


contract DE is ERC721Creator {
    constructor() ERC721Creator("Dead ends", "DE") {}
}
