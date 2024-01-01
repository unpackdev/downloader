// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Portrait
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    We are bullish on Pepe 🐸 wen Coinbase?    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator("Pepe Portrait", "PEPE") {}
}
