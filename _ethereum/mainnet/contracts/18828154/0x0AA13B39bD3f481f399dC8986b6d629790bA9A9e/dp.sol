// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: drop party
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    jokiargu 2023    //
//                     //
//                     //
/////////////////////////


contract dp is ERC721Creator {
    constructor() ERC721Creator("drop party", "dp") {}
}
