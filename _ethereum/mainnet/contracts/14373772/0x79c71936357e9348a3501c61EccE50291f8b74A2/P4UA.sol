
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peace 4 UA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Peace4Ukraine    //
//                     //
//                     //
/////////////////////////


contract P4UA is ERC721Creator {
    constructor() ERC721Creator("Peace 4 UA", "P4UA") {}
}
