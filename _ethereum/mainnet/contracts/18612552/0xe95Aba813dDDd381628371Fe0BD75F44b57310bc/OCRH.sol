// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OnchainRocks (honorary)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    follow the @OnchainRocks    //
//                                //
//                                //
////////////////////////////////////


contract OCRH is ERC721Creator {
    constructor() ERC721Creator("OnchainRocks (honorary)", "OCRH") {}
}
