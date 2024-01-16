
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE_Protocol_NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    $THE    //
//            //
//            //
////////////////


contract THE is ERC721Creator {
    constructor() ERC721Creator("THE_Protocol_NFT", "THE") {}
}
