// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Goose Generator by Dmitri Cherniak CCO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//    The reasonable man adapts himself to the world: the unreasonable one persists in trying to adapt the world to himself.     //
//    Therefore all progress depends on the unreasonable man." ― George Bernard Shaw                                             //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GGDC is ERC721Creator {
    constructor() ERC721Creator("Goose Generator by Dmitri Cherniak CCO", "GGDC") {}
}
