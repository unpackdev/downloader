
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MrKrabs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    They call me Krabs.    //
//                           //
//                           //
///////////////////////////////


contract MK is ERC721Creator {
    constructor() ERC721Creator("MrKrabs", "MK") {}
}
