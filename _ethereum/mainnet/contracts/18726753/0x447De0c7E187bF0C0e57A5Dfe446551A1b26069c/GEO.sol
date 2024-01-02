// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Geometric Punks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//       _____ _____  _    _ _   _ _  __ _____     //
//      / ____|  __ \| |  | | \ | | |/ // ____|    //
//     | |  __| |__) | |  | |  \| | ' /| (___      //
//     | | |_ |  ___/| |  | | . ` |  <  \___ \     //
//     | |__| | |    | |__| | |\  | . \ ____) |    //
//      \_____|_|     \____/|_| \_|_|\_\_____/     //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract GEO is ERC721Creator {
    constructor() ERC721Creator("Geometric Punks", "GEO") {}
}
