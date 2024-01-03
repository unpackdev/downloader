// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Plane Crazy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    "Plane Crazy" 1928                        //
//                                              //
//    First appearance of the famous mouse.     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract PC is ERC721Creator {
    constructor() ERC721Creator("Plane Crazy", "PC") {}
}
