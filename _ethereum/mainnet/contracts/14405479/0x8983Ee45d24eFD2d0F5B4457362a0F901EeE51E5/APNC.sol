
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Apple NFT Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    ETERIU    //
//              //
//              //
//////////////////


contract APNC is ERC721Creator {
    constructor() ERC721Creator("Apple NFT Collection", "APNC") {}
}
