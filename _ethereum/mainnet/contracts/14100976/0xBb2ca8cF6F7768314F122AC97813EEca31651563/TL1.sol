
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Lonely One
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    TheLonelyOne    //
//                    //
//                    //
////////////////////////


contract TL1 is ERC721Creator {
    constructor() ERC721Creator("The Lonely One", "TL1") {}
}
