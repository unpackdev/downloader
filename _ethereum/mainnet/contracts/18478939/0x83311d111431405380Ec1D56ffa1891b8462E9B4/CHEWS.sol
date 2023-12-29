// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Milk and Cookies by Matt Kane
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//    "You've all been very good. You really have. Okay. And uhm, I'd like to take you all out for Milk & Cookies now."    //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CHEWS is ERC721Creator {
    constructor() ERC721Creator("Milk and Cookies by Matt Kane", "CHEWS") {}
}
