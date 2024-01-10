
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PantyNectar
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    ▀██▀─▄███▄─▀██─██▀██▀▀█    //
//    ─██─███─███─██─██─██▄█     //
//    ─██─▀██▄██▀─▀█▄█▀─██▀█     //
//    ▄██▄▄█▀▀▀─────▀──▄██▄▄█    //
//                               //
//                               //
//                               //
///////////////////////////////////


contract PNTY is ERC721Creator {
    constructor() ERC721Creator("PantyNectar", "PNTY") {}
}
