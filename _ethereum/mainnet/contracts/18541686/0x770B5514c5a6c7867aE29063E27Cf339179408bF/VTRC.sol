// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Resurrection Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                  //
//    Introducing: The V Resurrection Collection. A dawn of a new era for the renowned artist, Valesh.                                                                                                                              //
//    Having taken a step back from the NFT universe to refine his craft in physical art, Valesh now returns to the digital realm with newfound confidence and vigor.                                                               //
//                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                  //
//    Months of meticulous work have culminated in a distinctive, signature style that brings him immense joy and fulfillment.                                                                                                      //
//    This collection represents a unique evolution in Valesh's artistic journey - one that is distinct from his physical portfolio.                                                                                                //
//                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                  //
//    Every piece within the V Resurrection Collection is an NFT exclusive, highlighting the artist's commitment to the digital art space.                                                                                          //
//    These pieces are not just artworks, but tokens of Valesh's artistic rebirth, each one carrying its own story and significance.                                                                                                //
//                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                  //
//    Join us in witnessing what is set to become the greatest comeback story in the NFT Art community. Be a part of this extraordinary journey as we celebrate the renaissance of Valesh through the V Resurrection Collection.    //
//                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VTRC is ERC721Creator {
    constructor() ERC721Creator("The Resurrection Collection", "VTRC") {}
}
