// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Temporal Echoes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//       ___       //
//      /   \      //
//     /     \     //
//    [   T   ]    //
//     \     /     //
//      \___/      //
//      |TEC|      //
//      |___|      //
//                 //
//                 //
//                 //
/////////////////////


contract TEC is ERC721Creator {
    constructor() ERC721Creator("Temporal Echoes", "TEC") {}
}
