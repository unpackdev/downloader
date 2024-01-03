// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Steamboat Willie
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    SteamboatWillie       //
//                          //
//    by notuncertainaxe    //
//                          //
//                          //
//////////////////////////////


contract SBW is ERC721Creator {
    constructor() ERC721Creator("Steamboat Willie", "SBW") {}
}
