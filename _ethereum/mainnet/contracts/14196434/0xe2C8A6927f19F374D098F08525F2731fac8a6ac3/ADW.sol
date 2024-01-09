
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ADW art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    New game NFT    //
//                    //
//                    //
////////////////////////


contract ADW is ERC721Creator {
    constructor() ERC721Creator("ADW art", "ADW") {}
}
