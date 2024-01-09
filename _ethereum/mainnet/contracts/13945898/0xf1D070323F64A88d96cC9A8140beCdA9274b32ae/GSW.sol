
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: genspiderweb
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    GENERATIVE SPIDERWEB 2022    //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract GSW is ERC721Creator {
    constructor() ERC721Creator("genspiderweb", "GSW") {}
}
