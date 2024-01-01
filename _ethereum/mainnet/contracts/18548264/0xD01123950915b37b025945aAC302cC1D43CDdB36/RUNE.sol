// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Runiverse Backstory
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    The Runiverse Backstory: Cannon Lore of the Singularity    //
//    by Merlin, Marcofine & ElfJTrul                            //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract RUNE is ERC1155Creator {
    constructor() ERC1155Creator("Runiverse Backstory", "RUNE") {}
}
