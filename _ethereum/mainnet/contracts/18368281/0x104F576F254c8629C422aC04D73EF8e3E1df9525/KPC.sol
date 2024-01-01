// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KUNTA's Permissionless Collaborations
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    CC0 Musical Productions    //
//                               //
//                               //
///////////////////////////////////


contract KPC is ERC721Creator {
    constructor() ERC721Creator("KUNTA's Permissionless Collaborations", "KPC") {}
}
