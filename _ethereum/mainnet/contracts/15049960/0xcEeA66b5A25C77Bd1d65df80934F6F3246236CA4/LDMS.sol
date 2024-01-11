
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Liladamers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//                               //
//     +-+-+-+-+-+-++-+-+-+-     //
//     |L|I|L|A|D|A|M|E|R|S|     //
//     +-+-+-+-+-+-+-+-+-+-+     //
//                               //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract LDMS is ERC721Creator {
    constructor() ERC721Creator("Liladamers", "LDMS") {}
}
