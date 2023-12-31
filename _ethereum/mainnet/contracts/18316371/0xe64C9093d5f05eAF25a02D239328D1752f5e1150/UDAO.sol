// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 🏧 | Meme Bank
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////
//              //
//              //
//    💰🦊💰    //
//              //
//              //
//////////////////


contract UDAO is ERC1155Creator {
    constructor() ERC1155Creator(unicode"🏧 | Meme Bank", "UDAO") {}
}
