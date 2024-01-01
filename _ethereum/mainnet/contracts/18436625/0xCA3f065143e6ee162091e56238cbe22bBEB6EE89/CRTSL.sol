// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cortisol - Hide in the dark
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    CORTISOL    //
//                //
//                //
////////////////////


contract CRTSL is ERC721Creator {
    constructor() ERC721Creator("Cortisol - Hide in the dark", "CRTSL") {}
}
