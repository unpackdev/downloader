
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sand Iconic Moments
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    We use sand to immortalize the most iconic moments on the Blockchain.     //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract SIM is ERC721Creator {
    constructor() ERC721Creator("Sand Iconic Moments", "SIM") {}
}
