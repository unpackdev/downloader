
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 马丁
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    马丁撸的经    //
//             //
//             //
/////////////////


contract MD is ERC721Creator {
    constructor() ERC721Creator(unicode"马丁", "MD") {}
}
