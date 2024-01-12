
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STEPNNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    0x2A036569DBbe7730D69ed664B74412E49f43C2C0    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract SNFT is ERC721Creator {
    constructor() ERC721Creator("STEPNNFT", "SNFT") {}
}
