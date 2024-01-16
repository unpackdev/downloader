
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lofigures
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     _        __ _                               //
//    | | ___  / _(_) __ _ _   _ _ __ ___  ___     //
//    | |/ _ \| |_| |/ _` | | | | '__/ _ \/ __|    //
//    | | (_) |  _| | (_| | |_| | | |  __/\__ \    //
//    |_|\___/|_| |_|\__, |\__,_|_|  \___||___/    //
//                   |___/                         //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract LOFI is ERC721Creator {
    constructor() ERC721Creator("lofigures", "LOFI") {}
}
