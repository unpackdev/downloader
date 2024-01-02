// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mixxed Media Madness
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                            //
//                                                                                                                                                            //
//    Mixxed Media Madness Collection by Akashi30.                                                                                                            //
//                                                                                                                                                            //
//    1. Edition drops once a month. With amount of max 12 to be minted.                                                                                      //
//                                                                                                                                                            //
//    2. 1 of 1 Drop will be always upcoming month after Edition. (DEC -> JAN, JAN -> FEB)                                                                    //
//                                                                                                                                                            //
//    3. Mint price is 0.025 raising by 0.005 every Drop.                                                                                                     //
//                                                                                                                                                            //
//    4. Mint Edition -> WL for next month drop with the same price as previous drop (as long as streak is going). WL = 3days to Mint-> public mint.          //
//                                                                                                                                                            //
//    5. 1/1 Drop will be available to collect only via Burning your Edition!! Different mechanics how to get to the 1/1! (Raffle, scavenger hunt, quiz).     //
//    Rule of first come first serve.                                                                                                                         //
//                                                                                                                                                            //
//    6. Each drop will be always TBA. Edition & 1/1 as well.                                                                                                 //
//                                                                                                                                                            //
//                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MMM is ERC721Creator {
    constructor() ERC721Creator("Mixxed Media Madness", "MMM") {}
}
