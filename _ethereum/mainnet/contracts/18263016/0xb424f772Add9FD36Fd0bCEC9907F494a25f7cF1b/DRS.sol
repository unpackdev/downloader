// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DAVID REES - SKETCHBOOK
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                                                                             //
//       ___|   |  /  ____| __ __|  ___|  |   |  __ )    _ \    _ \   |  /     //
//     \___ \   ' /   __|      |   |      |   |  __ \   |   |  |   |  ' /      //
//           |  . \   |        |   |      ___ |  |   |  |   |  |   |  . \      //
//     _____/  _|\_\ _____|   _|  \____| _|  _| ____/  \___/  \___/  _|\_\     //
//                                                                             //
//                                                                             //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract DRS is ERC721Creator {
    constructor() ERC721Creator("DAVID REES - SKETCHBOOK", "DRS") {}
}
