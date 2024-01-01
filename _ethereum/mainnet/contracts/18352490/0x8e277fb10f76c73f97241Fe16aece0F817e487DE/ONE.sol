// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Music Claimable
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//     ██████  ███    ██ ███████     //
//    ██    ██ ████   ██ ██          //
//    ██    ██ ██ ██  ██ █████       //
//    ██    ██ ██  ██ ██ ██          //
//     ██████  ██   ████ ███████     //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract ONE is ERC1155Creator {
    constructor() ERC1155Creator("Music Claimable", "ONE") {}
}
