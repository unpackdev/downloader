// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Go V3 Star
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Go v3 star    //
//                  //
//                  //
//////////////////////


contract GOV3 is ERC721Creator {
    constructor() ERC721Creator("Go V3 Star", "GOV3") {}
}
