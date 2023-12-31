// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Uptown
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
//    UUUUUUUU     UUUUUUUU                            tttt                                                                                        //
//    U::::::U     U::::::U                         ttt:::t                                                                                        //
//    U::::::U     U::::::U                         t:::::t                                                                                        //
//    UU:::::U     U:::::UU                         t:::::t                                                                                        //
//     U:::::U     U:::::Uppppp   ppppppppp   ttttttt:::::ttttttt       ooooooooooo wwwwwww           wwwww           wwwwwwwnnnn  nnnnnnnn        //
//     U:::::D     D:::::Up::::ppp:::::::::p  t:::::::::::::::::t     oo:::::::::::oow:::::w         w:::::w         w:::::w n:::nn::::::::nn      //
//     U:::::D     D:::::Up:::::::::::::::::p t:::::::::::::::::t    o:::::::::::::::ow:::::w       w:::::::w       w:::::w  n::::::::::::::nn     //
//     U:::::D     D:::::Upp::::::ppppp::::::ptttttt:::::::tttttt    o:::::ooooo:::::o w:::::w     w:::::::::w     w:::::w   nn:::::::::::::::n    //
//     U:::::D     D:::::U p:::::p     p:::::p      t:::::t          o::::o     o::::o  w:::::w   w:::::w:::::w   w:::::w      n:::::nnnn:::::n    //
//     U:::::D     D:::::U p:::::p     p:::::p      t:::::t          o::::o     o::::o   w:::::w w:::::w w:::::w w:::::w       n::::n    n::::n    //
//     U:::::D     D:::::U p:::::p     p:::::p      t:::::t          o::::o     o::::o    w:::::w:::::w   w:::::w:::::w        n::::n    n::::n    //
//     U::::::U   U::::::U p:::::p    p::::::p      t:::::t    tttttto::::o     o::::o     w:::::::::w     w:::::::::w         n::::n    n::::n    //
//     U:::::::UUU:::::::U p:::::ppppp:::::::p      t::::::tttt:::::to:::::ooooo:::::o      w:::::::w       w:::::::w          n::::n    n::::n    //
//      UU:::::::::::::UU  p::::::::::::::::p       tt::::::::::::::to:::::::::::::::o       w:::::w         w:::::w           n::::n    n::::n    //
//        UU:::::::::UU    p::::::::::::::pp          tt:::::::::::tt oo:::::::::::oo         w:::w           w:::w            n::::n    n::::n    //
//          UUUUUUUUU      p::::::pppppppp              ttttttttttt     ooooooooooo            www             www             nnnnnn    nnnnnn    //
//                         p:::::p                                                                                                                 //
//                         p:::::p                                                                                                                 //
//                        p:::::::p                                                                                                                //
//                        p:::::::p                                                                                                                //
//                        p:::::::p                                                                                                                //
//                        ppppppppp                                                                                                                //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TWN is ERC721Creator {
    constructor() ERC721Creator("Uptown", "TWN") {}
}
