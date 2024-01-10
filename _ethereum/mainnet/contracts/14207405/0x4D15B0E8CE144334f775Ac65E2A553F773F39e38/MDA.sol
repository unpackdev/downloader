
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Miggie's Digital Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Kdemonllkontrackt    //
//                         //
//                         //
/////////////////////////////


contract MDA is ERC721Creator {
    constructor() ERC721Creator("Miggie's Digital Art", "MDA") {}
}
