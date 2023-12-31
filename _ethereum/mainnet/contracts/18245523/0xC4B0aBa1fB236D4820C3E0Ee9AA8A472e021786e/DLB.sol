// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Degen LIKE a BOSS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ┳┓┏┓┏┓┏┓┳┓┏┓┳┓┏┓┳┓┏┓┏┓    //
//    ┃┃┣ ┃┓┣ ┃┃┣ ┣┫┣┫┃┃┃┃┗┓    //
//    ┻┛┗┛┗┛┗┛┛┗┗┛┛┗┛┗┻┛┗┛┗┛    //
//                              //
//                              //
//////////////////////////////////


contract DLB is ERC721Creator {
    constructor() ERC721Creator("Degen LIKE a BOSS", "DLB") {}
}
