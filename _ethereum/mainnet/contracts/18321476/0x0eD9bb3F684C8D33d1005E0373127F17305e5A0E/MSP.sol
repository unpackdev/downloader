// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 🕶️
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Sunglasses    //
//                  //
//                  //
//////////////////////


contract MSP is ERC721Creator {
    constructor() ERC721Creator(unicode"🕶️", "MSP") {}
}
