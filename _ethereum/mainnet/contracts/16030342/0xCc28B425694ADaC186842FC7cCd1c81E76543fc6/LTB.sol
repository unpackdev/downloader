
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: littlebirth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    LTB-Illustrator    //
//                       //
//                       //
///////////////////////////


contract LTB is ERC721Creator {
    constructor() ERC721Creator("littlebirth", "LTB") {}
}
