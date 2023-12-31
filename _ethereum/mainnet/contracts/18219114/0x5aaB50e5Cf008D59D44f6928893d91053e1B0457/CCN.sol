// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cool Cats NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                                  //
//    Cool Cats is a collection of 9,999 randomly generated and stylistically curated NFTs that exist on the Ethereum Blockchain. Cool Cat holders can participate in exclusive events such as NFT claims, raffles, community giveaways, and more. Remember, all cats are cool, but some are cooler than others.    //
//    - Cool Cats Collabs                                                                                                                                                                                                                                                                                           //
//    - Cool Cats Events                                                                                                                                                                                                                                                                                            //
//    - Cool Cats Achievements                                                                                                                                                                                                                                                                                      //
//    - Cool Cats Originals                                                                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CCN is ERC721Creator {
    constructor() ERC721Creator("Cool Cats NFT", "CCN") {}
}
