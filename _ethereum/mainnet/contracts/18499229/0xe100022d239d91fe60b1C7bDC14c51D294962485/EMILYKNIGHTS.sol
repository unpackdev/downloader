// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EmilyKnights Originals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    A limited edition collection of Emily Knights.    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract EMILYKNIGHTS is ERC721Creator {
    constructor() ERC721Creator("EmilyKnights Originals", "EMILYKNIGHTS") {}
}
