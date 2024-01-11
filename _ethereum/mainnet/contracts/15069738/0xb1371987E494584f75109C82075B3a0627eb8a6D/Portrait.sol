
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Charles Csuri Animation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//       ___  _                          //
//      / _ \(_)__  ___  ___ ___ ____    //
//     / ___/ / _ \/ _ \/ -_) -_) __/    //
//    /_/  /_/\___/_//_/\__/\__/_/       //
//                                       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract Portrait is ERC721Creator {
    constructor() ERC721Creator("Charles Csuri Animation", "Portrait") {}
}
