
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Machine Sentiments
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    No ASCII Art here (¬‿¬)            //
//    Machine Sentiments by David Loh    //
//                                       //
//                                       //
///////////////////////////////////////////


contract MS is ERC721Creator {
    constructor() ERC721Creator("Machine Sentiments", "MS") {}
}
