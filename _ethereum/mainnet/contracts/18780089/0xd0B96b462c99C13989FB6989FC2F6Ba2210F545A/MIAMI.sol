// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIAMI BEACH MEMORIES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MIAMI BEACH MEMORIES                                                                //
//    by MAX CAPACITY                                                                     //
//                                                                                        //
//    This project interrogates the liminal space between lived experience and            //
//    algorithmic anticipation, exploring the potential of artificial intelligence        //
//    to pre-empt and ultimately rewrite the narrative of memory. My journey to           //
//    Miami Art Basel transcended a mere physical excursion; it became a gateway to a     //
//    future woven from digital threads. Through the lens of generative AI, I crafted     //
//    a series of mnemonic artifacts – 4x6" glossy photographs depicting imagined         //
//    encounters in a yet-to-be-visited Miami Beach. These were not souvenirs of a        //
//    bygone trip, but rather testaments to a future shared, materialized through the     //
//    magic of silicon and code.                                                          //
//                                                                                        //
//    The chosen format, a nostalgic echo of vacation slides, serves a multifaceted       //
//    purpose. Firstly, it playfully subverts the performative nature of                  //
//    memory-sharing, inviting the viewer into a fabricated yet intimately personal       //
//    experience. Secondly, by physically dispersing these "pre-memories" amongst         //
//    newfound and longstanding companions in Miami, I sought to blur the boundaries      //
//    between anticipation and lived experience, collapsing the temporal distance         //
//    between dream and reality.                                                          //
//                                                                                        //
//    The subjects of these premonitions are not the sun-drenched sands or the art        //
//    deco facades, but the very individuals with whom I embarked on this shared          //
//    adventure. Their visages, rendered with hyperreal detail by the AI, stand in        //
//    stark contrast to my own intentionally distorted image. This dissonance serves      //
//    as a poignant metaphor for the ever-evolving tapestry of memory, hinting at the     //
//    potential for fabricated moments to morph into lived truths.                        //
//                                                                                        //
//    As the sands of time inevitably shift, and my own recollections succumb to the      //
//    inevitable distortions of experience, I hope these premonitory glimpses will        //
//    transcend their initial artifice. I yearn for them to become the preferred          //
//    narrative, a testament to the transformative power of human connection and the      //
//    shared stories that weave the fabric of our lives.                                  //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MIAMI is ERC721Creator {
    constructor() ERC721Creator("MIAMI BEACH MEMORIES", "MIAMI") {}
}
