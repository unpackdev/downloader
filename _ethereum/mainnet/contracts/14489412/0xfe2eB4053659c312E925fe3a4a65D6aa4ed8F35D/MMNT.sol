
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Momentum
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    //MMNTUM//    //
//                  //
//                  //
//////////////////////


contract MMNT is ERC721Creator {
    constructor() ERC721Creator("Momentum", "MMNT") {}
}
