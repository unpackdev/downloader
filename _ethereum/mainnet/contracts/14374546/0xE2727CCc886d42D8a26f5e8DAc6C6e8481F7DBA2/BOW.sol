
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xAthletes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    property of 0xAthletes     //
//                               //
//                               //
///////////////////////////////////


contract BOW is ERC721Creator {
    constructor() ERC721Creator("0xAthletes", "BOW") {}
}
