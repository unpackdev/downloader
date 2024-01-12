
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Engine battle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Engine battle    //
//                     //
//                     //
/////////////////////////


contract EBT is ERC721Creator {
    constructor() ERC721Creator("Engine battle", "EBT") {}
}
