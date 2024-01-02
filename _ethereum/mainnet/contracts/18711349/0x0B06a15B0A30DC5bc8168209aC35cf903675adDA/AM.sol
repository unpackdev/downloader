// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solid Dream
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    AM    //
//          //
//          //
//////////////


contract AM is ERC721Creator {
    constructor() ERC721Creator("Solid Dream", "AM") {}
}
