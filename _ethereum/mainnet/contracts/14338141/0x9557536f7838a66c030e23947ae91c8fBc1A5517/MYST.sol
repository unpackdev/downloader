
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mysterious
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    ░█▄█░█░█░█▀▀░▀█▀░█▀▀░█▀▄░▀█▀░█▀█░█░█░█▀▀    //
//    ░█░█░░█░░▀▀█░░█░░█▀▀░█▀▄░░█░░█░█░█░█░▀▀█    //
//    ░▀░▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract MYST is ERC721Creator {
    constructor() ERC721Creator("Mysterious", "MYST") {}
}
