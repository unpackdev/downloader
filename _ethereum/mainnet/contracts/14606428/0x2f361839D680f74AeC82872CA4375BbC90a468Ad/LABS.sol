
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Studio Experiments
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Studio Labs    //
//                   //
//                   //
///////////////////////


contract LABS is ERC721Creator {
    constructor() ERC721Creator("Studio Experiments", "LABS") {}
}
