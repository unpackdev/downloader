// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arefeh Norouzi
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//    ▄▀█ █▀█ █▀▀ █▀▀ █▀▀ █░█   █▄░█ █▀█ █▀█ █▀█ █░█ ▀█ █                    //
//    █▀█ █▀▄ ██▄ █▀░ ██▄ █▀█   █░▀█ █▄█ █▀▄ █▄█ █▄█ █▄ █                    //
//                                                                           //
//    ▄▀█ █░░ █░░   █▀█ █ █▀▀ █░█ ▀█▀ █▀   █▀█ █▀▀ █▀ █▀▀ █▀█ █░█ █▀▀ █▀▄    //
//    █▀█ █▄▄ █▄▄   █▀▄ █ █▄█ █▀█ ░█░ ▄█   █▀▄ ██▄ ▄█ ██▄ █▀▄ ▀▄▀ ██▄ █▄▀    //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract RFe is ERC1155Creator {
    constructor() ERC1155Creator("Arefeh Norouzi", "RFe") {}
}
