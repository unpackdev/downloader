
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTea
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    NFTea    //
//             //
//             //
/////////////////


contract TEA is ERC721Creator {
    constructor() ERC721Creator("NFTea", "TEA") {}
}
