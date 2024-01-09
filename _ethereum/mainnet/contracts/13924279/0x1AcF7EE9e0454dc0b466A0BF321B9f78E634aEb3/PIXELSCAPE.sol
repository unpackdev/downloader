
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PixelScapes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ____        |  |                          //
//    |  |  ____  |--|                          //
//    |  |  |  |  |  |       |>                 //
//    |  |--|  |  |  |_      __                 //
//    |  |  |  |  |--| |    /  \  |>  |>  |>    //
//    |  |  |  |  |  | |    |  |-----------     //
//    |  |  |  |  |  | |    |  |  |   |   |     //
//    --------------------------------------    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract PIXELSCAPE is ERC721Creator {
    constructor() ERC721Creator("PixelScapes", "PIXELSCAPE") {}
}
