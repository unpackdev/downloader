
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MonoCheetah
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract MCheetah is ERC721Creator {
    constructor() ERC721Creator("MonoCheetah", "MCheetah") {}
}
