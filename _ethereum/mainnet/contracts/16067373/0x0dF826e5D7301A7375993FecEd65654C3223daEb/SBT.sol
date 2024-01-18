
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sykz's Burn token
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    SYKZ    //
//            //
//            //
////////////////


contract SBT is ERC721Creator {
    constructor() ERC721Creator("Sykz's Burn token", "SBT") {}
}
