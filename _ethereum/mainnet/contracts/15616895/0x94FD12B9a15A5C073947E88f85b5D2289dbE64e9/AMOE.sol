
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: am open editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    /am/    //
//            //
//            //
////////////////


contract AMOE is ERC721Creator {
    constructor() ERC721Creator("am open editions", "AMOE") {}
}
