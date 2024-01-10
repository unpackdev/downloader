
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solovyova
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Solovyova    //
//                 //
//                 //
/////////////////////


contract SaART is ERC721Creator {
    constructor() ERC721Creator("Solovyova", "SaART") {}
}
