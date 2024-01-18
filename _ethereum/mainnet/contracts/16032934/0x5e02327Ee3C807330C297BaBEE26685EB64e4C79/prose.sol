
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: colour and prose
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    you should have left me at the station.     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract prose is ERC721Creator {
    constructor() ERC721Creator("colour and prose", "prose") {}
}
