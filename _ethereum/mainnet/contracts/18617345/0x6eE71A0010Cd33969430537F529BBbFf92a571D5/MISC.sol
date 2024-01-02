// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MISC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//                       //
//    ┏┓┳┳┓┏┓┳┳┓         //
//    ┗┓┃┃┃┣ ┃┃┃         //
//    ┗┛┻┛┗┗┛┛ ┗         //
//    ┓┏┓┏┓┓┏┓┏┳┓┏┓┳┓    //
//    ┃┫ ┃┃┃┫  ┃ ┣ ┃┃    //
//    ┛┗┛┗┛┛┗┛ ┻ ┗┛┛┗    //
//                       //
//                       //
//                       //
//                       //
///////////////////////////


contract MISC is ERC721Creator {
    constructor() ERC721Creator("MISC", "MISC") {}
}
