
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kool Kevins
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Kool Kevins    //
//                   //
//                   //
///////////////////////


contract KEV is ERC721Creator {
    constructor() ERC721Creator("Kool Kevins", "KEV") {}
}
