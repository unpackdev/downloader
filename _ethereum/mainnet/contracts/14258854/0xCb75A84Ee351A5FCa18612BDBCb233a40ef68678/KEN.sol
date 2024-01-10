
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WAKEN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    __        ___    _  _______ _   _     //
//    \ \      / / \  | |/ / ____| \ | |    //
//     \ \ /\ / / _ \ | ' /|  _| |  \| |    //
//      \ V  V / ___ \| . \| |___| |\  |    //
//       \_/\_/_/   \_\_|\_\_____|_| \_|    //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract KEN is ERC721Creator {
    constructor() ERC721Creator("WAKEN", "KEN") {}
}
