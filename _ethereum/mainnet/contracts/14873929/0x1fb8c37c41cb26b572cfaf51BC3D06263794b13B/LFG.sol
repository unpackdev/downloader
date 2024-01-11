
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LFG Twitter
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//     __         ______   ______        //
//    /\ \       /\  ___\ /\  ___\       //
//    \ \ \____  \ \  __\ \ \ \__ \      //
//     \ \_____\  \ \_\    \ \_____\     //
//      \/_____/   \/_/     \/_____/     //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract LFG is ERC721Creator {
    constructor() ERC721Creator("LFG Twitter", "LFG") {}
}
