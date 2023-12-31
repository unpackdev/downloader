// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FEVER
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    FEVER    //
//             //
//             //
/////////////////


contract FEVER is ERC721Creator {
    constructor() ERC721Creator("FEVER", "FEVER") {}
}
