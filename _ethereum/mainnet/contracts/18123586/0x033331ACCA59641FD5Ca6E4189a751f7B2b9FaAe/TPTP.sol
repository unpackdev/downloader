// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toputapu
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//    ,-,-,-.                             ,---.                 .          //
//    `,| | |   . ,-. . ,-,-. . . ,-,-.   |  -'  ,-. ,-. .  , . |- . .     //
//      | ; | . | | | | | | | | | | | |   |  ,-' |   ,-| | /  | |  | |     //
//      '   `-' ' ' ' ' ' ' ' `-^ ' ' '   `---|  '   `-^ `'   ' `' `-|     //
//                                         ,-.|                     /|     //
//                                         `-+'                    `-'     //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract TPTP is ERC721Creator {
    constructor() ERC721Creator("Toputapu", "TPTP") {}
}
