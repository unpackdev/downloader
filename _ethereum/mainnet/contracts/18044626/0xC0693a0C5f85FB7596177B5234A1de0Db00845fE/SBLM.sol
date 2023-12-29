// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Sublime
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//                              //
//    ┏┳┓┓     ┏┓  ┓ ┓•         //
//     ┃ ┣┓┏┓  ┗┓┓┏┣┓┃┓┏┳┓┏┓    //
//     ┻ ┛┗┗   ┗┛┗┻┗┛┗┗┛┗┗┗     //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract SBLM is ERC721Creator {
    constructor() ERC721Creator("The Sublime", "SBLM") {}
}
