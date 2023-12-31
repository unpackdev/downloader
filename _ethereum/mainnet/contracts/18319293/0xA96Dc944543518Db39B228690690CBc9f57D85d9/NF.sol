// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nef
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     _______          _____     //
//     \      \   _____/ ____\    //
//     /   |   \_/ __ \   __\     //
//    /    |    \  ___/|  |       //
//    \____|__  /\___  >__|       //
//            \/     \/           //
//                                //
//                                //
////////////////////////////////////


contract NF is ERC721Creator {
    constructor() ERC721Creator("Nef", "NF") {}
}
