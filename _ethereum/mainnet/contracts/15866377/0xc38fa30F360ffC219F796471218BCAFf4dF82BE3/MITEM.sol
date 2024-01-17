
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIRAI_ITEM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//     ■                     //
//     ■ ■■■■ ■■■■           //
//     ■   ■       ■■ ■■     //
//     ■   ■  ■    ■ ■ ■     //
//     ■   ■  ■■■■ ■   ■     //
//     ■   ■  ■    ■   ■     //
//     ■   ■  ■    ■   ■     //
//             ■■■           //
//                           //
//                           //
//                           //
//                           //
///////////////////////////////


contract MITEM is ERC721Creator {
    constructor() ERC721Creator("MIRAI_ITEM", "MITEM") {}
}
