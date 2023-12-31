// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ICEA3
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    ICEA3    //
//             //
//             //
/////////////////


contract ICEA3 is ERC721Creator {
    constructor() ERC721Creator("ICEA3", "ICEA3") {}
}
