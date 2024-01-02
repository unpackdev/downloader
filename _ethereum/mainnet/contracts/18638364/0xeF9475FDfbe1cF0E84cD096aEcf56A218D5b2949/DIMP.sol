// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sean Allen Fenn – Diamond In My Pocket
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//                       //
//    SAFE NEW MEDIA     //
//                       //
//                       //
//                       //
///////////////////////////


contract DIMP is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Sean Allen Fenn – Diamond In My Pocket", "DIMP") {}
}
