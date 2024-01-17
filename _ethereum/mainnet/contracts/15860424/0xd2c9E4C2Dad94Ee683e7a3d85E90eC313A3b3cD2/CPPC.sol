
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypto Punk Pet Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//    The Crypto Punk Pet Club is a collection of 530 unique punk pet NFTs - unique digital collectibles living on the Ethereum blockchain. Your Crypto Punk Pet seems to be more than a unique avatar...    //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CPPC is ERC721Creator {
    constructor() ERC721Creator("Crypto Punk Pet Club", "CPPC") {}
}
