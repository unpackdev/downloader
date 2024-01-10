
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: parasoul
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//    ───────────────────────────────────────    //
//    ╔═╗  ╔═╗  ╦═╗  ╔═╗  ╔═╗  ╔═╗  ╦ ╦  ╦       //
//    ╠═╝  ╠═╣  ╠╦╝  ╠═╣  ╚═╗  ║ ║  ║ ║  ║       //
//    ╩    ╩ ╩  ╩╚═  ╩ ╩  ╚═╝  ╚═╝  ╚═╝  ╩═╝     //
//    ───────────────────────────────────────    //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract PSOUL is ERC721Creator {
    constructor() ERC721Creator("parasoul", "PSOUL") {}
}
