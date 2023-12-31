// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitch Kitsch
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//     .--..  .---..--..   ..   ..---..-.  .--..   .    //
//    :    |    | :    |   ||  /   | (   ):    |   |    //
//    | --.|    | |    |---||-'    |  `-. |    |---|    //
//    :   ||    | :    |   ||  \   | (   ):    |   |    //
//     `--''---''  `--''   ''   `  '  `-'  `--''   '    //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract GLTCHKTSCH is ERC1155Creator {
    constructor() ERC1155Creator("Glitch Kitsch", "GLTCHKTSCH") {}
}
