// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Momi Fan Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Fan Art Collection    //
//                          //
//                          //
//////////////////////////////


contract MFA is ERC721Creator {
    constructor() ERC721Creator("Momi Fan Art", "MFA") {}
}
