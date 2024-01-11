
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hype Pass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    Hype Pass                                                                                  //
//    // Do not mint this unless you know what you are doing                                     //
//    // Hype pass allows you to gain access to NFT tools, research, whale community and more    //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract HYPE is ERC721Creator {
    constructor() ERC721Creator("Hype Pass", "HYPE") {}
}
