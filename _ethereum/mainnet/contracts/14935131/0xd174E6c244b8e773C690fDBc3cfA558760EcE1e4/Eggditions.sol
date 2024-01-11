
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EggVolution
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    EggVolution    //
//                   //
//                   //
///////////////////////


contract Eggditions is ERC721Creator {
    constructor() ERC721Creator("EggVolution", "Eggditions") {}
}
