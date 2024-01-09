
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    PANDAMAN_NFT_CONTRACT    //
//                             //
//                             //
/////////////////////////////////


contract TEST is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
