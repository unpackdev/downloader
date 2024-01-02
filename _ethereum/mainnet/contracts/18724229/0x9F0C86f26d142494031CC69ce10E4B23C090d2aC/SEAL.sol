// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seal Everydays
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    SEAL EVERYDAYS by axe    //
//                             //
//                             //
/////////////////////////////////


contract SEAL is ERC721Creator {
    constructor() ERC721Creator("Seal Everydays", "SEAL") {}
}
