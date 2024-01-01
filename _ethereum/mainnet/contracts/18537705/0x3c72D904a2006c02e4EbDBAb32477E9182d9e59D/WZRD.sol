// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Warothys
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    The Warothy Collection, by A.C.K.     //
//                                          //
//                                          //
//////////////////////////////////////////////


contract WZRD is ERC721Creator {
    constructor() ERC721Creator("Warothys", "WZRD") {}
}
