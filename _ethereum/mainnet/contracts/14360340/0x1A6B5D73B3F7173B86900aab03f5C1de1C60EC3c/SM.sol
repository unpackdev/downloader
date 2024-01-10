
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scott Move
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    \|/\|/\|/(` _  |-|-|\/|     _ \|/\|/\|/      //
//    /|\/|\/|\_)(_()|_|_|  |()\/(/_/|\/|\/|\      //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract SM is ERC721Creator {
    constructor() ERC721Creator("Scott Move", "SM") {}
}
