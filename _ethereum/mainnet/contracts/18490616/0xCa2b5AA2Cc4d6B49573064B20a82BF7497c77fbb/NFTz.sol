// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTSMACKZ
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    NFTSMACKZ     //
//                  //
//                  //
//////////////////////


contract NFTz is ERC1155Creator {
    constructor() ERC1155Creator("NFTSMACKZ", "NFTz") {}
}
