// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Polyhedral Money NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    PNFT    //
//            //
//            //
////////////////


contract MEMO is ERC721Creator {
    constructor() ERC721Creator("Polyhedral Money NFT", "MEMO") {}
}
