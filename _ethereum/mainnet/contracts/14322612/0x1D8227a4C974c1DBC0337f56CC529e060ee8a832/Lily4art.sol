
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lily4art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Lily4art    //
//                //
//                //
////////////////////


contract Lily4art is ERC721Creator {
    constructor() ERC721Creator("Lily4art", "Lily4art") {}
}
