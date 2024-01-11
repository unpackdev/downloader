
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Noone Airdrop Token
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Infinite Art GLitch    //
//                           //
//                           //
///////////////////////////////


contract NAT is ERC721Creator {
    constructor() ERC721Creator("Noone Airdrop Token", "NAT") {}
}
