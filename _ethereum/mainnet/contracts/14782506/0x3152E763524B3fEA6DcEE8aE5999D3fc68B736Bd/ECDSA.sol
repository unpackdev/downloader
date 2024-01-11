
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0x_ECDSA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    0 x E C D S A    //
//                     //
//                     //
/////////////////////////


contract ECDSA is ERC721Creator {
    constructor() ERC721Creator("0x_ECDSA", "ECDSA") {}
}
