
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: neodaoist
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                              |               _)        |       //
//      __ \    _ \   _ \    _` |   _` |   _ \   |   __|  __|     //
//      |   |   __/  (   |  (   |  (   |  (   |  | \__ \  |       //
//     _|  _| \___| \___/  \__,_| \__,_| \___/  _| ____/ \__|     //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract NDST is ERC721Creator {
    constructor() ERC721Creator("neodaoist", "NDST") {}
}
