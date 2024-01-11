
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hueviews
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ░░▄▄░▄███▄         //
//    ▄▀▀▀▀░▄▄▄░▀▀▀▀▄    //
//    █▒▒▒▒█░░░█▒▒▒▒█    //
//    █▒▒▒▒▀▄▄▄▀▒▒▒▒█    //
//    ▀▄▄▄▄▄▄▄▄▄▄▄▄▄▀    //
//                       //
//                       //
///////////////////////////


contract HUE is ERC721Creator {
    constructor() ERC721Creator("hueviews", "HUE") {}
}
