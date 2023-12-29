// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WeAreSoDucked Honorary
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//    ░░      ░░  ░░░░  ░░      ░░  ░░░░  ░░      ░░    //
//    ▒  ▒▒▒▒  ▒  ▒▒▒▒  ▒  ▒▒▒▒  ▒  ▒▒▒  ▒▒  ▒▒▒▒  ▒    //
//    ▓  ▓▓ ▓  ▓  ▓▓▓▓  ▓  ▓▓▓▓  ▓     ▓▓▓▓  ▓▓▓▓▓▓▓    //
//    █  ███   █  ████  █        █  ███  ██  ████  █    //
//    ██      ███      ██  ████  █  ████  ██      ██    //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract WASDH is ERC721Creator {
    constructor() ERC721Creator("WeAreSoDucked Honorary", "WASDH") {}
}
