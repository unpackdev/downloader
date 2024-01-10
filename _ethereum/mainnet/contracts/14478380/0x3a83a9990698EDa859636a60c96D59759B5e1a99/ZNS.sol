
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zouns
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    _______________((((((()))))))))_______________________    //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract ZNS is ERC721Creator {
    constructor() ERC721Creator("Zouns", "ZNS") {}
}
