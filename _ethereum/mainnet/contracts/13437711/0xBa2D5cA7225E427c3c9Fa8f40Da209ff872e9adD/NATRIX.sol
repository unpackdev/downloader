
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cryptonatrix
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    RRRRRw                                ;                                            //
//    RRRRRR@w                             #RRp                                    $-    //
//    RRRRRRRRR#_                         0RRRRW                                 ,w@     //
//    RRRRRRRRRRRDw                     ,RRRRRRRW                              #RRRRK    //
//    RRRRRRRRRRRRRRw_                 /RRRRRRRRRR_                           0RRRRRR    //
//      TRRRRRRRRRRRRR@w              #RRRRRRRRRRRRw        ,wwwwwc_         [RRRRRR     //
//        0RRRRRRRRRRRRRRWm_ _,_     0RRRRRRRRRRRRRRK    z@RRRRRRRRRRw       ]RRRRM      //
//        'RRRRRRRRRRRRRRRRRRRRRK    ,'"0RRRRRRRRRF_/   0RRRRRRRRRRRRRR_    #RRR"        //
//         RRRRRRRRRRRRRRRRRRRRRRW    TKw_?RRRM",gRF   0RRRR"     ?RRRRRWwwRRRR"         //
//         [RRRRRRRRRRRRRRRRRRRRRR@    '0RRWcy@RRR  ,  RRRRR       '0RRRRRRRRR"          //
//          ^RRRRRRRRRRRRRRRRRRRRRR@_    TRRRRRR"    W 0RRRR_        'MRRRRM"            //
//             "RRRRR, "0RRRRRRRRRRRRw    ^0RRR      0  0RRRRKw,___,wg#@@@@wc            //
//                TRRRp  `0RRRRRRRRRRR      T"      #M   "0RRRRRRRRRRRRRRRRRRRw          //
//                  "RRW   ^0RRRRRRRRR            ,R"       "MRRRRRRM""'  "0RRRL         //
//                    TR@_   TRRRRRR"             RR         _,__          [RRRH         //
//                      TRw    "'                 0R_     ,@RRRRRRRW,     aRRRR          //
//                       '0W                       TRR@#@RRRR"""TRRRRRR@@RRRRR           //
//                         ?Rw                       '"^M""        TRRRRRRR^             //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract NATRIX is ERC721Creator {
    constructor() ERC721Creator("Cryptonatrix", "NATRIX") {}
}
