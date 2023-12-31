// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oscillations
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Oscillations - ideartist    //
//                                //
//                                //
////////////////////////////////////


contract OSC is ERC1155Creator {
    constructor() ERC1155Creator("Oscillations", "OSC") {}
}
