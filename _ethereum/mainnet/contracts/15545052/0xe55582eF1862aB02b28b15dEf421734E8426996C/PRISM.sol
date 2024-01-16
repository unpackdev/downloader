
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Prism Foundation Living Trust
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    00000010    //
//                //
//                //
////////////////////


contract PRISM is ERC721Creator {
    constructor() ERC721Creator("Prism Foundation Living Trust", "PRISM") {}
}
