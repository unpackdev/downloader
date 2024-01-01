// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jaša
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


contract JR is ERC721Creator {
    constructor() ERC721Creator(unicode"Jaša", "JR") {}
}
