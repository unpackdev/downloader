
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moment Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    THE MOMENT CLUB    //
//                       //
//                       //
///////////////////////////


contract TheMomentClub is ERC721Creator {
    constructor() ERC721Creator("Moment Club", "TheMomentClub") {}
}
