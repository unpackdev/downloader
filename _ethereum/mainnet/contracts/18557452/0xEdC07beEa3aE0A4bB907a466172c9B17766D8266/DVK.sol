// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Too much Internet
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    It ascii mark, who dis?    //
//                               //
//                               //
///////////////////////////////////


contract DVK is ERC721Creator {
    constructor() ERC721Creator("Too much Internet", "DVK") {}
}
