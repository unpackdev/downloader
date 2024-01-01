// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MMIRAGE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    M M I R A G E    //
//                     //
//                     //
/////////////////////////


contract MMRG is ERC721Creator {
    constructor() ERC721Creator("MMIRAGE", "MMRG") {}
}
