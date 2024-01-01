// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OnchainTest01
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    OCA Test    //
//                //
//                //
////////////////////


contract OCA is ERC721Creator {
    constructor() ERC721Creator("OnchainTest01", "OCA") {}
}
