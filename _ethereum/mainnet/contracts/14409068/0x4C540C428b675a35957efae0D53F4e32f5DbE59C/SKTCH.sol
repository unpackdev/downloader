
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hrunz sketches
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//           __          __        __                             //
//    .-----|  |--.-----|  |_.----|  |--.-----.-----.             //
//    |__ --|    <|  -__|   _|  __|     |  -__|__ --|             //
//    |_____|__|__|_____|____|____|__|__|_____|_____|             //
//                                                    by hrunz    //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract SKTCH is ERC721Creator {
    constructor() ERC721Creator("hrunz sketches", "SKTCH") {}
}
