// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TIMELESS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//    ████████ ██ ███    ███ ███████ ██      ███████ ███████ ███████     //
//       ██    ██ ████  ████ ██      ██      ██      ██      ██          //
//       ██    ██ ██ ████ ██ █████   ██      █████   ███████ ███████     //
//       ██    ██ ██  ██  ██ ██      ██      ██           ██      ██     //
//       ██    ██ ██      ██ ███████ ███████ ███████ ███████ ███████     //
//                                                                       //
//                           BY MIKKO LAGERSTEDT                         //
//                                                                       //
//       ███████ ██████  ██ ████████ ██  ██████  ███    ██ ███████       //
//       ██      ██   ██ ██    ██    ██ ██    ██ ████   ██ ██            //
//       █████   ██   ██ ██    ██    ██ ██    ██ ██ ██  ██ ███████       //
//       ██      ██   ██ ██    ██    ██ ██    ██ ██  ██ ██      ██       //
//       ███████ ██████  ██    ██    ██  ██████  ██   ████ ███████       //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract TMLS is ERC1155Creator {
    constructor() ERC1155Creator("TIMELESS", "TMLS") {}
}
