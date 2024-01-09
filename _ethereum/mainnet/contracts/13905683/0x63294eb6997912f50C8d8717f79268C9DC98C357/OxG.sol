
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xG
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//                 //
//       0xG       //
//    _________    //
//                 //
//                 //
/////////////////////


contract OxG is ERC721Creator {
    constructor() ERC721Creator("0xG", "OxG") {}
}
