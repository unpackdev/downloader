
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kvasir Vanir Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    888    d8P  888     888        d8888     //
//    888   d8P   888     888       d88888     //
//    888  d8P    888     888      d88P888     //
//    888d88K     Y88b   d88P     d88P 888     //
//    8888888b     Y88b d88P     d88P  888     //
//    888  Y88b     Y88o88P     d88P   888     //
//    888   Y88b     Y888P     d8888888888     //
//    888    Y88b     Y8P     d88P     888     //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract KVA is ERC721Creator {
    constructor() ERC721Creator("Kvasir Vanir Art", "KVA") {}
}
