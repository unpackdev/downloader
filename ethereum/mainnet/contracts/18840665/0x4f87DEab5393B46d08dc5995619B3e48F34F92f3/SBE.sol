// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Studio Brasch Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Studio Brasch Editions    //
//                              //
//                              //
//////////////////////////////////


contract SBE is ERC721Creator {
    constructor() ERC721Creator("Studio Brasch Editions", "SBE") {}
}
