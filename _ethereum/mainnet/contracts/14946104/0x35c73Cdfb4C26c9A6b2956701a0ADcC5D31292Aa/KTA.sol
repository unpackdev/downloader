
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KariTheArtist
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//    KKKKKKKKK    KKKKKKK                                      iiii TTTTTTTTTTTTTTTTTTTTTTThhhhhhh                                              AAA                                           tttt            iiii                            tttt              //
//    K:::::::K    K:::::K                                     i::::iT:::::::::::::::::::::Th:::::h                                             A:::A                                       ttt:::t           i::::i                        ttt:::t              //
//    K:::::::K    K:::::K                                      iiii T:::::::::::::::::::::Th:::::h                                            A:::::A                                      t:::::t            iiii                         t:::::t              //
//    K:::::::K   K::::::K                                           T:::::TT:::::::TT:::::Th:::::h                                           A:::::::A                                     t:::::t                                         t:::::t              //
//    KK::::::K  K:::::KKK  aaaaaaaaaaaaa  rrrrr   rrrrrrrrr  iiiiiiiTTTTTT  T:::::T  TTTTTT h::::h hhhhh           eeeeeeeeeeee             A:::::::::A          rrrrr   rrrrrrrrr   ttttttt:::::ttttttt    iiiiiii     ssssssssss   ttttttt:::::ttttttt        //
//      K:::::K K:::::K     a::::::::::::a r::::rrr:::::::::r i:::::i        T:::::T         h::::hh:::::hhh      ee::::::::::::ee          A:::::A:::::A         r::::rrr:::::::::r  t:::::::::::::::::t    i:::::i   ss::::::::::s  t:::::::::::::::::t        //
//      K::::::K:::::K      aaaaaaaaa:::::ar:::::::::::::::::r i::::i        T:::::T         h::::::::::::::hh   e::::::eeeee:::::ee       A:::::A A:::::A        r:::::::::::::::::r t:::::::::::::::::t     i::::i ss:::::::::::::s t:::::::::::::::::t        //
//      K:::::::::::K                a::::arr::::::rrrrr::::::ri::::i        T:::::T         h:::::::hhh::::::h e::::::e     e:::::e      A:::::A   A:::::A       rr::::::rrrrr::::::rtttttt:::::::tttttt     i::::i s::::::ssss:::::stttttt:::::::tttttt        //
//      K:::::::::::K         aaaaaaa:::::a r:::::r     r:::::ri::::i        T:::::T         h::::::h   h::::::he:::::::eeeee::::::e     A:::::A     A:::::A       r:::::r     r:::::r      t:::::t           i::::i  s:::::s  ssssss       t:::::t              //
//      K::::::K:::::K      aa::::::::::::a r:::::r     rrrrrrri::::i        T:::::T         h:::::h     h:::::he:::::::::::::::::e     A:::::AAAAAAAAA:::::A      r:::::r     rrrrrrr      t:::::t           i::::i    s::::::s            t:::::t              //
//      K:::::K K:::::K    a::::aaaa::::::a r:::::r            i::::i        T:::::T         h:::::h     h:::::he::::::eeeeeeeeeee     A:::::::::::::::::::::A     r:::::r                  t:::::t           i::::i       s::::::s         t:::::t              //
//    KK::::::K  K:::::KKKa::::a    a:::::a r:::::r            i::::i        T:::::T         h:::::h     h:::::he:::::::e             A:::::AAAAAAAAAAAAA:::::A    r:::::r                  t:::::t    tttttt i::::i ssssss   s:::::s       t:::::t    tttttt    //
//    K:::::::K   K::::::Ka::::a    a:::::a r:::::r           i::::::i     TT:::::::TT       h:::::h     h:::::he::::::::e           A:::::A             A:::::A   r:::::r                  t::::::tttt:::::ti::::::is:::::ssss::::::s      t::::::tttt:::::t    //
//    K:::::::K    K:::::Ka:::::aaaa::::::a r:::::r           i::::::i     T:::::::::T       h:::::h     h:::::h e::::::::eeeeeeee  A:::::A               A:::::A  r:::::r                  tt::::::::::::::ti::::::is::::::::::::::s       tt::::::::::::::t    //
//    K:::::::K    K:::::K a::::::::::aa:::ar:::::r           i::::::i     T:::::::::T       h:::::h     h:::::h  ee:::::::::::::e A:::::A                 A:::::A r:::::r                    tt:::::::::::tti::::::i s:::::::::::ss          tt:::::::::::tt    //
//    KKKKKKKKK    KKKKKKK  aaaaaaaaaa  aaaarrrrrrr           iiiiiiii     TTTTTTTTTTT       hhhhhhh     hhhhhhh    eeeeeeeeeeeeeeAAAAAAA                   AAAAAAArrrrrrr                      ttttttttttt  iiiiiiii  sssssssssss              ttttttttttt      //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KTA is ERC721Creator {
    constructor() ERC721Creator("KariTheArtist", "KTA") {}
}
