
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anonymous Nobody's Music
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//         ;;;;;;;;;;;;;;;;;;;     //
//         ;;;;;;;;;;;;;;;;;;;     //
//         ;                 ;     //
//         ;                 ;     //
//         ;                 ;     //
//         ;                 ;     //
//         ;                 ;     //
//         ;                 ;     //
//         ;                 ;     //
//    ,;;;;;            ,;;;;;     //
//    ;;;;;;            ;;;;;;     //
//    `;;;;'            `;;;;'     //
//                                 //
//                                 //
/////////////////////////////////////


contract MUSIC is ERC721Creator {
    constructor() ERC721Creator("Anonymous Nobody's Music", "MUSIC") {}
}
