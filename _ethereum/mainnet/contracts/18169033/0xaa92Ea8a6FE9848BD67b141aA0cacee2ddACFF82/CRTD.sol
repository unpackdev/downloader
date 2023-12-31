// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Curated
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                 eskylabs  _           _     //
//       ___ _   _ _ __ __ _| |_ ___  __| |    //
//      / __| | | | '__/ _` | __/ _ \/ _` |    //
//     | (__| |_| | | | (_| | ||  __/ (_| |    //
//      \___|\__,_|_|  \__,_|\__\___|\__,_|    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CRTD is ERC721Creator {
    constructor() ERC721Creator("Curated", "CRTD") {}
}
