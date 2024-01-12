
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Early in the world
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    There was a blood moon in the sky.                                                                                                                                              //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    A bonfire will burn out next to him.                                                                                                                                            //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    In the distance seemed endless wilderness.                                                                                                                                      //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    When Luo Yong woke up from his dream, he found himself in a dilapidated camp with no one around him and the cold wind blowing like it was about to blow him into a stupor...    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    What the hell is going on here?                                                                                                                                                 //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EITW is ERC721Creator {
    constructor() ERC721Creator("Early in the world", "EITW") {}
}
