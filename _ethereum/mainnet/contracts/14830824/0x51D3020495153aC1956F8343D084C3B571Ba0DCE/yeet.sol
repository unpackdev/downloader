
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yeetomatic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    ASCII MARK    //
//                  //
//                  //
//////////////////////


contract yeet is ERC721Creator {
    constructor() ERC721Creator("yeetomatic", "yeet") {}
}
