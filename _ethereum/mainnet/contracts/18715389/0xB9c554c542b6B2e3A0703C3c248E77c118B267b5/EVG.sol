// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evergreen
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    [🌿]    //
//            //
//            //
////////////////


contract EVG is ERC721Creator {
    constructor() ERC721Creator("Evergreen", "EVG") {}
}
