
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Prompt Studies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//     ■ ■ ■ ■ ■ ■ ■ ■ ■ ■     //
//                             //
//                             //
/////////////////////////////////


contract PRMPTS is ERC721Creator {
    constructor() ERC721Creator("Prompt Studies", "PRMPTS") {}
}
