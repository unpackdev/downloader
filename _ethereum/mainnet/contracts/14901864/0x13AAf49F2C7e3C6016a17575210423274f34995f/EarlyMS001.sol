
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Creator of Sin's
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Early Sin's Storage    //
//                           //
//                           //
///////////////////////////////


contract EarlyMS001 is ERC721Creator {
    constructor() ERC721Creator("The Creator of Sin's", "EarlyMS001") {}
}
