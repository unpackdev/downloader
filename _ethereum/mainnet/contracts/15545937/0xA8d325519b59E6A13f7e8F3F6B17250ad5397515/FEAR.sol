
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fear zone
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    $    //
//         //
//         //
/////////////


contract FEAR is ERC721Creator {
    constructor() ERC721Creator("Fear zone", "FEAR") {}
}
