
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LEGO Collection NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    ETERIU    //
//              //
//              //
//////////////////


contract LEGO is ERC721Creator {
    constructor() ERC721Creator("LEGO Collection NFT", "LEGO") {}
}
