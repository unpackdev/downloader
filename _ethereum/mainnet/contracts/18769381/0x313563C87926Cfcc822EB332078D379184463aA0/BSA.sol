// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bathroom Stall Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//     ,,,           >X<           ___              //
//        (o o)         (o o)         (o o)         //
//    ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract BSA is ERC721Creator {
    constructor() ERC721Creator("Bathroom Stall Art", "BSA") {}
}
