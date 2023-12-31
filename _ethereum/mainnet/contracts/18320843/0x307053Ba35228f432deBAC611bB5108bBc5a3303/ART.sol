// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Poster Art
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//    .-,--.         .                    .      //
//     '|__/ ,-. ,-. |- ,-. ,-.   ,-. ,-. |-     //
//     ,|    | | `-. |  |-' |     ,-| |   |      //
//     `'    `-' `-' `' `-' '     `-^ '   `'     //
//                                               //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract ART is ERC1155Creator {
    constructor() ERC1155Creator("Poster Art", "ART") {}
}
