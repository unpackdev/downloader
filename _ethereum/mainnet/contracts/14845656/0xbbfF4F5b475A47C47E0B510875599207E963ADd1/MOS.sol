
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Designer
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    @thedesignerof    //
//                      //
//                      //
//////////////////////////


contract MOS is ERC721Creator {
    constructor() ERC721Creator("The Designer", "MOS") {}
}
