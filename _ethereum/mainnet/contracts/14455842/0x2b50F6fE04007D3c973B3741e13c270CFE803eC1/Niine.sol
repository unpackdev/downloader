
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Niine's-Verse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    . . .-. .-. . . .-. .-.   . . .-. .-. .-. .-.     //
//    |\|  |   |  |\| |-  `-.   | | |-  |(  `-. |-      //
//    ' ` `-' `-' ' ` `-' `-'   `.' `-' ' ' `-' `-'     //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract Niine is ERC721Creator {
    constructor() ERC721Creator("Niine's-Verse", "Niine") {}
}
