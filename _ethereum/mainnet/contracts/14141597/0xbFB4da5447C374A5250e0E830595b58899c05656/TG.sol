
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Think Good
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Think Good    //
//                  //
//                  //
//////////////////////


contract TG is ERC721Creator {
    constructor() ERC721Creator("Think Good", "TG") {}
}
