// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Barcelona
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    viva cataluña    //
//                     //
//                     //
/////////////////////////


contract BCLN is ERC721Creator {
    constructor() ERC721Creator("Barcelona", "BCLN") {}
}
