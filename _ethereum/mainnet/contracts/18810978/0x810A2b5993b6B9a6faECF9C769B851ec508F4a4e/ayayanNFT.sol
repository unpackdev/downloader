// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ayayanmax
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//    ╔═╗╦ ╦╔═╗╔╦╗╔═╗═╗ ╦    //
//    ╠═╣╚╦╝╠═╣║║║╠═╣╔╩╦╝    //
//    ╩ ╩ ╩ ╩ ╩╩ ╩╩ ╩╩ ╚═    //
//                           //
//                           //
///////////////////////////////


contract ayayanNFT is ERC721Creator {
    constructor() ERC721Creator("ayayanmax", "ayayanNFT") {}
}
