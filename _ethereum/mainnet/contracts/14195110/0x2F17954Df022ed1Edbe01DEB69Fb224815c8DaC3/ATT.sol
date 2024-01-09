
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: arttest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Become first NFT collection    //
//                                   //
//                                   //
///////////////////////////////////////


contract ATT is ERC721Creator {
    constructor() ERC721Creator("arttest", "ATT") {}
}
