// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kernal test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    kt test    //
//               //
//               //
///////////////////


contract kt is ERC721Creator {
    constructor() ERC721Creator("kernal test", "kt") {}
}
