// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: C O M P Ξ Z
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//       ___                                   //
//      / __\___  _ __ ___  _ __   ___ ____    //
//     / /  / _ \| '_ ` _ \| '_ \ / _ \_  /    //
//    / /__| (_) | | | | | | |_) |  __// /     //
//    \____/\___/|_| |_| |_| .__/ \___/___|    //
//                         |_|                 //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CPZ is ERC721Creator {
    constructor() ERC721Creator(unicode"C O M P Ξ Z", "CPZ") {}
}
