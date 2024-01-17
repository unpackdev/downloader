
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WonderFi Hackathon Winners
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    20 Winner Trophies for 2022    //
//                                   //
//                                   //
///////////////////////////////////////


contract WNDR is ERC721Creator {
    constructor() ERC721Creator("WonderFi Hackathon Winners", "WNDR") {}
}
