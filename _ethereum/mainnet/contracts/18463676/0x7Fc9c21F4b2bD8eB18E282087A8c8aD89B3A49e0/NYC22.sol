// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Archive: New York City (2022)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    Archive: New York City (2022) by Nathan A. Bauman    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract NYC22 is ERC721Creator {
    constructor() ERC721Creator("Archive: New York City (2022)", "NYC22") {}
}
