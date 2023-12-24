// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Succubus
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//                         _               //
//     ___ _ _ ___ ___ _ _| |_ _ _ ___     //
//    |_ -| | |  _|  _| | | . | | |_ -|    //
//    |___|___|___|___|___|___|___|___|    //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract BUS is ERC721Creator {
    constructor() ERC721Creator("Succubus", "BUS") {}
}
