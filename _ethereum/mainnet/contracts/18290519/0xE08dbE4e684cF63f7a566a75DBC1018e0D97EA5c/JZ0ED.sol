// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jestem Zero Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    ██      █████  ███    ███      ██████      //
//    ██     ██   ██ ████  ████     ██  ████     //
//    ██     ███████ ██ ████ ██     ██ ██ ██     //
//    ██     ██   ██ ██  ██  ██     ████  ██     //
//    ██     ██   ██ ██      ██      ██████      //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract JZ0ED is ERC1155Creator {
    constructor() ERC1155Creator("Jestem Zero Editions", "JZ0ED") {}
}
