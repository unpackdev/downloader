// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arid
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    It's always cloudy but it never rains...    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract GORGE is ERC721Creator {
    constructor() ERC721Creator("Arid", "GORGE") {}
}
