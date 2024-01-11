
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOMENTS BY LGHT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ███    ███ ███    ███ ███    ██ ████████ ███████     //
//    ████  ████ ████  ████ ████   ██    ██    ██          //
//    ██ ████ ██ ██ ████ ██ ██ ██  ██    ██    ███████     //
//    ██  ██  ██ ██  ██  ██ ██  ██ ██    ██         ██     //
//    ██      ██ ██      ██ ██   ████    ██    ███████     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract MMNTS is ERC721Creator {
    constructor() ERC721Creator("MOMENTS BY LGHT", "MMNTS") {}
}
