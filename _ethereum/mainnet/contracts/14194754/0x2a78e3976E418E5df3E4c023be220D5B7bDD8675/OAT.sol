
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oatmeals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    OATMEAL NFL PLAYERS    //
//                           //
//                           //
///////////////////////////////


contract OAT is ERC721Creator {
    constructor() ERC721Creator("Oatmeals", "OAT") {}
}
