// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aeneas Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    [🏛️🌊🏛️]    //
//                  //
//                  //
//////////////////////


contract AENEAS is ERC721Creator {
    constructor() ERC721Creator("Aeneas Editions", "AENEAS") {}
}
