
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Apple NFT Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Apple NFT Collection    //
//                            //
//                            //
////////////////////////////////


contract APPLE is ERC721Creator {
    constructor() ERC721Creator("Apple NFT Collection", "APPLE") {}
}
