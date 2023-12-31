// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WORTHLESS NFT
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    nothing to see here    //
//                           //
//                           //
///////////////////////////////


contract NOP is ERC1155Creator {
    constructor() ERC1155Creator("WORTHLESS NFT", "NOP") {}
}
