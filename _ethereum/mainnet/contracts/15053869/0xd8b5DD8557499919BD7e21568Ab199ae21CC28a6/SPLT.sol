
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Splat's Personal Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Splat's Personal NFT collection    //
//                                       //
//                                       //
///////////////////////////////////////////


contract SPLT is ERC721Creator {
    constructor() ERC721Creator("Splat's Personal Collection", "SPLT") {}
}
