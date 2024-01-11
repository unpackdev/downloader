
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: House of Flying Artists
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//    When the birds came to me, they came to me in infinite ways.                                       //
//    Their voices were the rays of golden light, that touched me in my darkest moments.                 //
//    My gratitude towards them burst my heart open.                                                     //
//                                                                                                       //
//    They asked me to express their essence.                                                            //
//    It was the bird nature in all of us, that wanted to be seen.                                       //
//    For me the birds are, what is free, light, daring and happy.                                       //
//    They know all about the element of air. They know how to dance with the wind.                      //
//    They know how to sing and they sing the songs of the trees.                                        //
//                                                                                                       //
//    Time to set them free on this planet and within us.                                                //
//    So we can be free to fly high and explore.                                                         //
//    With every breath we take, with every pulse of our beating hearts.                                 //
//                                                                                                       //
//    The birds are my home, my heart and my love. They are here to bring more freedom. To all of us.    //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HOFA is ERC721Creator {
    constructor() ERC721Creator("House of Flying Artists", "HOFA") {}
}
