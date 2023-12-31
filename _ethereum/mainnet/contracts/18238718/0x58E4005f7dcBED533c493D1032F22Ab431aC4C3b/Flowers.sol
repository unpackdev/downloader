// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neoflowers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    Flowers    //
//               //
//               //
///////////////////


contract Flowers is ERC721Creator {
    constructor() ERC721Creator("Neoflowers", "Flowers") {}
}
