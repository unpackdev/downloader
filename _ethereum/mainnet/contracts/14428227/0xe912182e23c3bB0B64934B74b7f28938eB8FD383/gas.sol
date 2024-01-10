
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 我的gas好低
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    gas真特么低    //
//               //
//               //
///////////////////


contract gas is ERC721Creator {
    constructor() ERC721Creator(unicode"我的gas好低", "gas") {}
}
