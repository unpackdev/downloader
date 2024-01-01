// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inland County
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Inland County    //
//                     //
//                     //
/////////////////////////


contract inland is ERC721Creator {
    constructor() ERC721Creator("Inland County", "inland") {}
}
