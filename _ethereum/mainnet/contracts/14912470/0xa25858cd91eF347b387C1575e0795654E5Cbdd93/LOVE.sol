
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Out of Love for All
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//       ___       _            __     __                   __                         //
//      /___\_   _| |_    ___  / _|   / /  _____   _____   / _| ___  _ __              //
//     //  // | | | __|  / _ \| |_   / /  / _ \ \ / / _ \ | |_ / _ \| '__|             //
//    / \_//| |_| | |_  | (_) |  _| / /__| (_) \ V /  __/ |  _| (_) | |_ _ _           //
//    \___/  \__,_|\__|  \___/|_|   \____/\___/ \_/ \___| |_|  \___/|_(_|_|_)          //
//                                                                                     //
//    All creatures great & small, on this tiny blue marble hurtling through space.    //
//                                                                                     //
//    =============================================================================    //
//                                                                                     //
//    Existence here...the existence of _all_ of this, really, is quite amazing, to    //
//    say the least.                                                                   //
//                                                                                     //
//    Our lives here on earth are so brief in the grand scheme of things.  A blip.     //
//                                                                                     //
//    How will you spend the time you have left?                                       //
//                                                                                     //
//    =============================================================================    //
//                                                                                     //
//    I was very fortunate - my home life as a child was wonderful, full of love       //
//    and support in so many ways.                                                     //
//                                                                                     //
//    After early adventures in electronics:                                           //
//      "Can I take apart the stereo?"                                                 //
//      "Do you think can put it back together again, so that it's working?"           //
//      "I should be able to - I'll be careful."                                       //
//                                                                                     //
//    ...and so the stereo was carefully disassembled, examined, and re-assembled      //
//    without a hitch. (They believed deeply in my abilities, ever more as I grew,     //
//    though I think my Mum breathed a sigh of relief when the stereo was back         //
//    together and working ;)                                                          //
//                                                                                     //
//    My Dad was one of the most loving people you could hope to meet, and oh, so      //
//    very patient. It seemed as though he had a positive effect on every person       //
//    he met, in lasting ways.                                                         //
//                                                                                     //
//    =============================================================================    //
//                                                                                     //
//    As for me, I did a deep dive into rabbit holes of science, technology,           //
//    mathematics, and so on. I wound up being a pretty good problem solver, we'll     //
//    say, which made for a good career...all the while carrying those early           //
//    lessons and experiences with me...and so we come back to "How will you spend     //
//    the time you have left?"                                                         //
//                                                                                     //
//    Don't get me wrong, there are situations where that quote from Roadhouse         //
//    needs to be kept in mind, "Be nice, until it's time to not be nice."             //
//    Generally speaking, though, it's time to be nice, and some people are too        //
//    quick to switch over.                                                            //
//                                                                                     //
//    I do my best to act out of love and kindness in pretty much all that I do.       //
//                                                                                     //
//    It influences how I am toward my children, family, friends, and strangers.       //
//                                                                                     //
//    It comes to bear on the work I'm doing - driving positive change in the          //
//    world, aiming to make it a better place for all, in ways which will endure.      //
//                                                                                     //
//    That work is what finally had me embrace blockchain tech, instead of simply      //
//    appreciating the design of it - the prospect of connecting my material-world     //
//    efforts to on-chain solutions, to have it drive positive change for              //
//    generations.                                                                     //
//                                                                                     //
//    Diving into smart-contracts led me to the vibrant population of artists,         //
//    collectors, and community members in the NFT space.  Ultimately, it's what       //
//    led to this contract - in order to start sharing my own art, created over        //
//    the years, as a modest beginning.                                                //
//                                                                                     //
//    It's what led me to you.  I hope that you enjoy what I have to share.            //
//                                                                                     //
//                                                                                     //
//            @@@@@@           @@@@@@                                                  //
//          @@@@@@@@@@       @@@@@@@@@@                                                //
//        @@@@@@@@@@@@@@   @@@@@@@@@@@@@@                                              //
//      @@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@                                            //
//     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                           //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                          //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                          //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                          //
//     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                           //
//      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                            //
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             //
//        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                              //
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@                                                //
//            @@@@@@@@@@@@@@@@@@@@@@@                                                  //
//              @@@@@@@@@@@@@@@@@@@                                                    //
//                @@@@@@@@@@@@@@@                                                      //
//                  @@@@@@@@@@@                                                        //
//                    @@@@@@@                                                          //
//                      @@@                                                            //
//                       @                                                             //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract LOVE is ERC721Creator {
    constructor() ERC721Creator("Out of Love for All", "LOVE") {}
}
