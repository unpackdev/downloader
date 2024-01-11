
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Essential Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//    .-. .-. .-. .-. . . .-. .-. .-. .           //
//    |-  `-. `-. |-  |\|  |   |  |-| |           //
//    `-' `-' `-' `-' ' `  '  `-' ` ' `-'         //
//                                                //
//    .-. .-. .   .   .-. .-. .-. .-. .-. . .     //
//    |   | | |   |   |-  |    |   |  | | |\|     //
//    `-' `-' `-' `-' `-' `-'  '  `-' `-' ' `     //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract EssentialCollection is ERC721Creator {
    constructor() ERC721Creator("Essential Collection", "EssentialCollection") {}
}
