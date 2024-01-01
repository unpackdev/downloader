// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: zero gravity
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                     •       //
//    ┓┏┓┏┓┏┓  ┏┓┏┓┏┓┓┏┓╋┓┏    //
//    ┗┗ ┛ ┗┛  ┗┫┛ ┗┻┗┛┗┗┗┫    //
//    ┓     ┏┓  ┛      ┓┏ ┛    //
//    ┣┓┓┏  ┃┃┏┓╋┏┓┏┓  ┃┃      //
//    ┗┛┗┫  ┣┛┗ ┗┛ ┗┻  ┗┛•     //
//       ┛                     //
//                             //
//                             //
/////////////////////////////////


contract grvty is ERC721Creator {
    constructor() ERC721Creator("zero gravity", "grvty") {}
}
