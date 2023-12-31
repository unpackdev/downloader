// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Esse Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//    //     / _  )/___)/___)/ _  )    //    //
//    //    ( (/ /|___ |___ ( (/ /     //    //
//    //     \____|___/(___/ \____)    //    //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract ESSE is ERC1155Creator {
    constructor() ERC1155Creator("Esse Editions", "ESSE") {}
}
