
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UGLYS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//          FUNNY COLECTİON    //
//                             //
//                             //
/////////////////////////////////


contract UGS is ERC721Creator {
    constructor() ERC721Creator("UGLYS", "UGS") {}
}
