
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cities of the Metaverse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                              //
//    Cities of the Metaverse - Genesis Mint                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                              //
//    A seemingly forgotten part of the city that has seen better times. A haunting urban space built to be experienced in the Metaverse, where everyone from street artists, photographers, graffiti artists, and painters can gather, host events, display their NFTs, and explore. Welcome to the Cities of the Metaverse    //
//                                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CotM is ERC721Creator {
    constructor() ERC721Creator("Cities of the Metaverse", "CotM") {}
}
