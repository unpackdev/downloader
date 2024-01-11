
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLIPDENZA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//    999 hand flipped FlipDenza. Testing the boundaries of parody, provenance and censorship in web3. We will donate 25% of all our income to the victims of the war in the ukraine.    //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FDZ is ERC721Creator {
    constructor() ERC721Creator("FLIPDENZA", "FDZ") {}
}
