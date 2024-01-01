// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Shine And Geek Emblem Token
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    //This is a useful token for something by A Shine And Geek//    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract ASAG is ERC721Creator {
    constructor() ERC721Creator("A Shine And Geek Emblem Token", "ASAG") {}
}
