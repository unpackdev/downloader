
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Agency-Kui
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Agency-Kui    //
//                  //
//                  //
//////////////////////


contract KUI is ERC721Creator {
    constructor() ERC721Creator("Agency-Kui", "KUI") {}
}
