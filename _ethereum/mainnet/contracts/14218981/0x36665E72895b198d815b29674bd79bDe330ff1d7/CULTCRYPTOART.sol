
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cult Crypto Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Cult Crypto Art    //
//                       //
//                       //
///////////////////////////


contract CULTCRYPTOART is ERC721Creator {
    constructor() ERC721Creator("Cult Crypto Art", "CULTCRYPTOART") {}
}
