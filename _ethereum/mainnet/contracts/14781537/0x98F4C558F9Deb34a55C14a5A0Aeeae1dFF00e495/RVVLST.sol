
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Revivalist Design Furniture
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                             //
//                                                                                                                             //
//    RRRRRRRRRRRRRRRRR                                                    lllllll                           tttt              //
//    R::::::::::::::::R                                                   l:::::l                        ttt:::t              //
//    R::::::RRRRRR:::::R                                                  l:::::l                        t:::::t              //
//    RR:::::R     R:::::R                                                 l:::::l                        t:::::t              //
//      R::::R     R:::::Rvvvvvvv           vvvvvvvvvvvvvv           vvvvvvvl::::l     ssssssssss   ttttttt:::::ttttttt        //
//      R::::R     R:::::R v:::::v         v:::::v  v:::::v         v:::::v l::::l   ss::::::::::s  t:::::::::::::::::t        //
//      R::::RRRRRR:::::R   v:::::v       v:::::v    v:::::v       v:::::v  l::::l ss:::::::::::::s t:::::::::::::::::t        //
//      R:::::::::::::RR     v:::::v     v:::::v      v:::::v     v:::::v   l::::l s::::::ssss:::::stttttt:::::::tttttt        //
//      R::::RRRRRR:::::R     v:::::v   v:::::v        v:::::v   v:::::v    l::::l  s:::::s  ssssss       t:::::t              //
//      R::::R     R:::::R     v:::::v v:::::v          v:::::v v:::::v     l::::l    s::::::s            t:::::t              //
//      R::::R     R:::::R      v:::::v:::::v            v:::::v:::::v      l::::l       s::::::s         t:::::t              //
//      R::::R     R:::::R       v:::::::::v              v:::::::::v       l::::l ssssss   s:::::s       t:::::t    tttttt    //
//    RR:::::R     R:::::R        v:::::::v                v:::::::v       l::::::ls:::::ssss::::::s      t::::::tttt:::::t    //
//    R::::::R     R:::::R         v:::::v                  v:::::v        l::::::ls::::::::::::::s       tt::::::::::::::t    //
//    R::::::R     R:::::R          v:::v                    v:::v         l::::::l s:::::::::::ss          tt:::::::::::tt    //
//    RRRRRRRR     RRRRRRR           vvv                      vvv          llllllll  sssssssssss              ttttttttttt      //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RVVLST is ERC721Creator {
    constructor() ERC721Creator("Revivalist Design Furniture", "RVVLST") {}
}
