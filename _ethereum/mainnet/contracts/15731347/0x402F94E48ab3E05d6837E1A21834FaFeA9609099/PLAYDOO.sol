
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Playground Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Such Playground, much fun.    //
//                                  //
//                                  //
//////////////////////////////////////


contract PLAYDOO is ERC721Creator {
    constructor() ERC721Creator("Playground Contract", "PLAYDOO") {}
}
