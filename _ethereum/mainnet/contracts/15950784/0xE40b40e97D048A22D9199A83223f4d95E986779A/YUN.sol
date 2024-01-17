
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Private Room - A Genesis Music Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     __   ___   _ _  _ ___ ___ ___     //
//     \ \ / / | | | \| |_ _/ __| __|    //
//      \ V /| |_| | .` || | (__| _|     //
//       |_|  \___/|_|\_|___\___|___|    //
//                                       //
//                                       //
///////////////////////////////////////////


contract YUN is ERC721Creator {
    constructor() ERC721Creator("Private Room - A Genesis Music Collection", "YUN") {}
}
