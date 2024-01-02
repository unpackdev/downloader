// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RGZ
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    AIRDROP RGZ    //
//                   //
//                   //
///////////////////////


contract RGZ is ERC1155Creator {
    constructor() ERC1155Creator("RGZ", "RGZ") {}
}
