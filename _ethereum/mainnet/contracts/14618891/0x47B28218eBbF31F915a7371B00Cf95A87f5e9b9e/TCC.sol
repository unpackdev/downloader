
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tubby cats collabs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    tubby cat collaborations     //
//                                 //
//                                 //
/////////////////////////////////////


contract TCC is ERC721Creator {
    constructor() ERC721Creator("tubby cats collabs", "TCC") {}
}
