
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SnoopDogg
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    For all the snoop fans.     //
//                                //
//                                //
////////////////////////////////////


contract SDG is ERC721Creator {
    constructor() ERC721Creator("SnoopDogg", "SDG") {}
}
