// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy Pupz Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    HPC🐶🐶    //
//               //
//               //
///////////////////


contract HPC is ERC721Creator {
    constructor() ERC721Creator("Happy Pupz Club", "HPC") {}
}
