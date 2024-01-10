
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SINCLAIR
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    metacubism    //
//                  //
//                  //
//////////////////////


contract SINC is ERC721Creator {
    constructor() ERC721Creator("SINCLAIR", "SINC") {}
}
