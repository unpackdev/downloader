// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: voids
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     _  _   __  __  ____  ____     //
//    / )( \ /  \(  )(    \/ ___)    //
//    \ \/ /(  O ))(  ) D (\___ \    //
//     \__/  \__/(__)(____/(____/    //
//    Creator seansalexa             //
//                                   //
//                                   //
///////////////////////////////////////


contract VDS is ERC721Creator {
    constructor() ERC721Creator("voids", "VDS") {}
}
