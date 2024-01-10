
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Apps with love
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    ♥    //
//         //
//         //
/////////////


contract AWL is ERC721Creator {
    constructor() ERC721Creator("Apps with love", "AWL") {}
}
