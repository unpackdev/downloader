
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nifty Ash Arts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Nifty Creative              //
//    Multidisciplinary Artist    //
//    NFT Creator                 //
//    niftycre.com                //
//                                //
//                                //
////////////////////////////////////


contract NIFTY is ERC721Creator {
    constructor() ERC721Creator("Nifty Ash Arts", "NIFTY") {}
}
