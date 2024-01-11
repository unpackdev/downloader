
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In Flight Entertainment
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    TAKE FLIGHT          //
//                         //
//    WITH LOVE, ROLLER    //
//                         //
//                         //
/////////////////////////////


contract IFE is ERC721Creator {
    constructor() ERC721Creator("In Flight Entertainment", "IFE") {}
}
