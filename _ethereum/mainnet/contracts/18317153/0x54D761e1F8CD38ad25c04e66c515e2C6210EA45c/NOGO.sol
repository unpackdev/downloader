// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 💰| Disaster Capitalism
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    👁️👄👁️    //
//                //
//                //
////////////////////


contract NOGO is ERC721Creator {
    constructor() ERC721Creator(unicode"💰| Disaster Capitalism", "NOGO") {}
}
