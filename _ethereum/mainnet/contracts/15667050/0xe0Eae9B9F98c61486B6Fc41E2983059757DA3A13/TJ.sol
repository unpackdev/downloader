
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TAIJI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ████████  █████  ██      ██ ██     //
//       ██    ██   ██ ██      ██ ██     //
//       ██    ███████ ██      ██ ██     //
//       ██    ██   ██ ██ ██   ██ ██     //
//       ██    ██   ██ ██  █████  ██     //
//                                       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract TJ is ERC721Creator {
    constructor() ERC721Creator("TAIJI", "TJ") {}
}
