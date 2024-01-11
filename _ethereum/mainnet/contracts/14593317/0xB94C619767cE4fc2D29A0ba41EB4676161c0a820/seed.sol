
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nfSeeds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract seed is ERC721Creator {
    constructor() ERC721Creator("nfSeeds", "seed") {}
}
