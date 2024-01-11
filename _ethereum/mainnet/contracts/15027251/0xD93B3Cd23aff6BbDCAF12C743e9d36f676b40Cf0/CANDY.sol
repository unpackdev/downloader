
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Candy Box
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    🍬    //
//          //
//          //
//          //
//////////////


contract CANDY is ERC721Creator {
    constructor() ERC721Creator("Candy Box", "CANDY") {}
}
