
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KickOff
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    BigShot.    //
//                //
//                //
////////////////////


contract KickOff is ERC721Creator {
    constructor() ERC721Creator("KickOff", "KickOff") {}
}
