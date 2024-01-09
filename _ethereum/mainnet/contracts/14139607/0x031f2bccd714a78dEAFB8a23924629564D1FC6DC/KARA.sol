
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karafurus
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Karafuru NFT    //
//                    //
//                    //
////////////////////////


contract KARA is ERC721Creator {
    constructor() ERC721Creator("Karafurus", "KARA") {}
}
