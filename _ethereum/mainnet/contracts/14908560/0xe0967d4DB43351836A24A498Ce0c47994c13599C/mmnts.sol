
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mementos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    .  . .-. .  . .-. . . .-. .-. .-.     //
//    |\/| |-  |\/| |-  |\|  |  | | `-.     //
//    '  ` `-' '  ` `-' ' `  '  `-' `-'     //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract mmnts is ERC721Creator {
    constructor() ERC721Creator("Mementos", "mmnts") {}
}
