// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Titties
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//       _    _  _    _    _               //
//      | |_ |_|| |_ | |_ |_| ___  ___     //
//      |  _|| ||  _||  _|| || -_||_ -|    //
//      |_|  |_||_|  |_|  |_||___||___|    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract TTS is ERC1155Creator {
    constructor() ERC1155Creator("Titties", "TTS") {}
}
