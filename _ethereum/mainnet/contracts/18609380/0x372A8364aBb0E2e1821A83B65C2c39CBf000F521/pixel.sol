// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Worn Pixels
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    tristan rettich 2023 - worn pixels collection    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract pixel is ERC721Creator {
    constructor() ERC721Creator("Worn Pixels", "pixel") {}
}
