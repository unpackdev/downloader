
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tynezphoto
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    SESSIONS    //
//                //
//                //
////////////////////


contract SESH is ERC721Creator {
    constructor() ERC721Creator("Tynezphoto", "SESH") {}
}
