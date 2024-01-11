
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mytho Glyphs Airdrop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    I love you     //
//                   //
//                   //
///////////////////////


contract Myth is ERC721Creator {
    constructor() ERC721Creator("Mytho Glyphs Airdrop", "Myth") {}
}
