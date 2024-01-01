// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heroes of Rock: Trading Cards
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//          ___  __   __   ___  __      __   ___     __   __   __           //
//    |__| |__  |__) /  \ |__  /__`    /  \ |__     |__) /  \ /  ` |__/     //
//    |  | |___ |  \ \__/ |___ .__/    \__/ |       |  \ \__/ \__, |  \     //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract HORTC is ERC721Creator {
    constructor() ERC721Creator("Heroes of Rock: Trading Cards", "HORTC") {}
}
