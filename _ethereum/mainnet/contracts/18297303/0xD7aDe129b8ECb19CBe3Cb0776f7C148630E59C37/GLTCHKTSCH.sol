// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitch Kitsch
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//     .--..  .---..--..   ..   ..---..-.  .--..   .       //
//    :    |    | :    |   ||  /   | (   ):    |   |       //
//    | --.|    | |    |---||-'    |  `-. |    |---|       //
//    :   ||    | :    |   ||  \   | (   ):    |   |       //
//     `--''---''  `--''   ''   `  '  `-'  `--''   '       //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract GLTCHKTSCH is ERC721Creator {
    constructor() ERC721Creator("Glitch Kitsch", "GLTCHKTSCH") {}
}
