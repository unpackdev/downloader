// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Earth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//                         |    |         //
//       _ \   _` |   __|  __|  __ \      //
//       __/  (   |  |     |    | | |     //
//     \___| \__,_| _|    \__| _| |_|     //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract EARTH is ERC721Creator {
    constructor() ERC721Creator("Earth", "EARTH") {}
}
