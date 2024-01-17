
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KALOV Genesis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    -    //
//    .    //
//    -    //
//    .    //
//    -    //
//         //
//         //
/////////////


contract KALOV is ERC721Creator {
    constructor() ERC721Creator("KALOV Genesis", "KALOV") {}
}
