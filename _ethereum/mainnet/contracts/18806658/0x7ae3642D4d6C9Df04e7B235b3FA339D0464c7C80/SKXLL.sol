// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SKXLL
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    SKXLL will... come    //
//                          //
//                          //
//////////////////////////////


contract SKXLL is ERC721Creator {
    constructor() ERC721Creator("SKXLL", "SKXLL") {}
}
