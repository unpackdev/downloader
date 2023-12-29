// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wolf Game    🔹
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                       //
//    Thousands of Sheep and Wolves compete on a farm in the metaverse. A tempting prize of $WOOL awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.    //
//                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WFG is ERC721Creator {
    constructor() ERC721Creator(unicode"Wolf Game    🔹", "WFG") {}
}
