// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cyberdream
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    hello world                                   //
//                                                  //
//                                                  //
//    𝘢𝘳𝘵 𝘮𝘢𝘥𝘦 𝘣𝘺 𝘴𝘦𝘳𝘢𝘥𝘰𝘢 | 2023    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract cyberdream is ERC721Creator {
    constructor() ERC721Creator("cyberdream", "cyberdream") {}
}
