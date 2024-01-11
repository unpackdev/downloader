
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moonbears NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Moonbears NFT    //
//                     //
//                     //
//                     //
/////////////////////////


contract MBB is ERC721Creator {
    constructor() ERC721Creator("Moonbears NFT", "MBB") {}
}
