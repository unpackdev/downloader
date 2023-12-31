// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Testing Auction
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    Testing Auction — Dummy contract. Please don't engage.    //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract TT is ERC721Creator {
    constructor() ERC721Creator("Testing Auction", "TT") {}
}
