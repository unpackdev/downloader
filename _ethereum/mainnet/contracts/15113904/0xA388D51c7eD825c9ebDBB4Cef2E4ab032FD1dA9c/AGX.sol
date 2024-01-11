
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ars Goetia Mint
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//      _, __,  _,    _,  _, __, ___ _  _,   _  ,    //
//     / \ |_) (_    / _ / \ |_   |  | /_\   '\/     //
//     |~| | \ , )   \ / \ / |    |  | | |    /\     //
//     ~ ~ ~ ~  ~     ~   ~  ~~~  ~  ~ ~ ~   ~  ~    //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract AGX is ERC721Creator {
    constructor() ERC721Creator("Ars Goetia Mint", "AGX") {}
}
