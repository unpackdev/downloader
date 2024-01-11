
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YouNeek
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//    __   __          _   _           _        //
//    \ \ / /         | \ | |         | |       //
//     \ V /___  _   _|  \| | ___  ___| | __    //
//      \ // _ \| | | | . ` |/ _ \/ _ \ |/ /    //
//      | | (_) | |_| | |\  |  __/  __/   <     //
//      \_/\___/ \__,_\_| \_/\___|\___|_|\_\    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract YNEEK is ERC721Creator {
    constructor() ERC721Creator("YouNeek", "YNEEK") {}
}
