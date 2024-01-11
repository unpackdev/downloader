
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: From Sand to Summit by Rod Trevino
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//    .-,--'                  .---.           .    .         .---.                   .      //
//     \|__  ,-. ,-. ,-,-.    \___  ,-. ,-. ,-|    |- ,-.    \___  . . ,-,-. ,-,-. . |-     //
//      |    |   | | | | |        \ ,-| | | | |    |  | |        \ | | | | | | | | | |      //
//     `'    '   `-' ' ' '    `---' `-^ ' ' `-^    `' `-'    `---' `-^ ' ' ' ' ' ' ' `'     //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract SandxSummit is ERC721Creator {
    constructor() ERC721Creator("From Sand to Summit by Rod Trevino", "SandxSummit") {}
}
