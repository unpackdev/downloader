
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CT's
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Sackman Jones    //
//                     //
//                     //
/////////////////////////


contract CTS is ERC721Creator {
    constructor() ERC721Creator("CT's", "CTS") {}
}
