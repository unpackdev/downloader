
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hikari
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    Hikari    //
//              //
//              //
//////////////////


contract HIKARI is ERC721Creator {
    constructor() ERC721Creator("Hikari", "HIKARI") {}
}
