
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moonbirds Official
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Moonbirds Official    //
//                          //
//                          //
//////////////////////////////


contract MBO is ERC721Creator {
    constructor() ERC721Creator("Moonbirds Official", "MBO") {}
}
