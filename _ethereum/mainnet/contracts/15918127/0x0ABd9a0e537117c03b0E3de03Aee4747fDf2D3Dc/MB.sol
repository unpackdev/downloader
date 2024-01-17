
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minebuu
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    Minebuu    //
//               //
//               //
///////////////////


contract MB is ERC721Creator {
    constructor() ERC721Creator("Minebuu", "MB") {}
}
