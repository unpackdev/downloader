
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: donne
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼     //
//       _              △       //
//     _| |___ ___ ___ ___      //
//    | . | . |   |   | -_|     //
//    |___|___|_|_|_|_|___|     //
//                              //
//    ▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼     //
//                              //
//                              //
//////////////////////////////////


contract MUSIC is ERC721Creator {
    constructor() ERC721Creator("donne", "MUSIC") {}
}
