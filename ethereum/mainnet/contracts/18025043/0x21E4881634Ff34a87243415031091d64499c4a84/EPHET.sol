// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ephemeral Eternities
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    E²    //
//          //
//          //
//////////////


contract EPHET is ERC721Creator {
    constructor() ERC721Creator("Ephemeral Eternities", "EPHET") {}
}
