
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rolex Collection NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Rolex    //
//             //
//             //
/////////////////


contract ROLEX is ERC721Creator {
    constructor() ERC721Creator("Rolex Collection NFT", "ROLEX") {}
}
