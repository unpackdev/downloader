// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VISUALIZE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    .   , ,  ,-.  .  .  ,.  ,    , ,---, ,--.     //
//    |  /  | (   ` |  | /  \ |    |    /  |        //
//    | /   |  `-.  |  | |--| |    |   /   |-       //
//    |/    | .   ) |  | |  | |    |  /    |        //
//    '     '  `-'  `--` '  ' `--' ' '---' `--'     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract VIZ is ERC721Creator {
    constructor() ERC721Creator("VISUALIZE", "VIZ") {}
}
