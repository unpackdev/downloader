
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: What Did the Deep Sea Say by Sara Macel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    WHAT DID THE DEEP SEA SAY BY SARA MACEL    //
//    IMAGES © SARA MACEL                        //
//    ALL RIGHTS RESERVED                        //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract SEA is ERC721Creator {
    constructor() ERC721Creator("What Did the Deep Sea Say by Sara Macel", "SEA") {}
}
