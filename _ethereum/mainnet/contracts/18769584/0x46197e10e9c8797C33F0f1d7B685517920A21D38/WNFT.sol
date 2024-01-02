// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: World NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ██     ██ ███    ██ ███████ ████████     //
//    ██     ██ ████   ██ ██         ██        //
//    ██  █  ██ ██ ██  ██ █████      ██        //
//    ██ ███ ██ ██  ██ ██ ██         ██        //
//     ███ ███  ██   ████ ██         ██        //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract WNFT is ERC721Creator {
    constructor() ERC721Creator("World NFTs", "WNFT") {}
}
