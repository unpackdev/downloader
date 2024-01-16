
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tuya
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    牛逼闪闪放光芒    //
//               //
//               //
///////////////////


contract CAT is ERC721Creator {
    constructor() ERC721Creator("tuya", "CAT") {}
}
