// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Une Fleur pour MOCA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    a1111ac011d0    //
//                    //
//                    //
////////////////////////


contract FleurMOCA is ERC721Creator {
    constructor() ERC721Creator("Une Fleur pour MOCA", "FleurMOCA") {}
}
